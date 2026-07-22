# pitflow-bootstrap

Bootstrap da infraestrutura compartilhada do Pitflow na AWS.

Este repositório cria o bucket usado pelo backend do Terraform e o secret
`pitflow/bootstrap` no AWS Secrets Manager. O Terraform gerencia somente o
contêiner do secret. O conteúdo JSON é atualizado pelo GitHub Actions para que
outros repositórios possam alterar apenas as chaves sob sua responsabilidade.

## Responsabilidades

- `pitflow-bootstrap`: cria o secret e mescla credenciais, nomes dos bancos e
  configurações compartilhadas.
- `pitflow-database`: cria o RDS e atualiza os hosts e portas dos bancos sem
  substituir as outras chaves do secret.

Essa separação impede que uma nova execução do bootstrap restaure os hosts para
valores vazios depois que o RDS for criado.

## Terraform

Os arquivos ficam em `infra/terraform`:

- `provider.tf`: configura Terraform, provider AWS e região.
- `secret.tf`: cria o secret `pitflow/bootstrap`, sem gerenciar uma versão.
- `removed.tf`: remove a versão antiga apenas do state, sem destruir a versão
  existente no AWS Secrets Manager.
- `outputs.tf`: expõe o nome do secret.
- `backend.tf`: armazena o state no bucket S3
  `tfstate-backend-fiap-pitflow`.

Como novos valores sensíveis não são enviados ao Terraform, eles não são
armazenados no state deste repositório. Na primeira execução após esta migração,
o bloco `removed` preserva a versão antiga no AWS Secrets Manager e remove
somente seu vínculo com o state.

## Conteúdo do secret

O secret contém as seguintes chaves:

```text
PITFLOW_OPERATION_DB_NAME
PITFLOW_OPERATION_DB_USERNAME
PITFLOW_OPERATION_DB_PASSWORD
PITFLOW_OPERATION_DB_HOST
PITFLOW_OPERATION_DB_PORT

PITFLOW_INVENTORY_DB_NAME
PITFLOW_INVENTORY_DB_USERNAME
PITFLOW_INVENTORY_DB_PASSWORD
PITFLOW_INVENTORY_DB_HOST
PITFLOW_INVENTORY_DB_PORT

PITFLOW_REGISTRY_DB_NAME
PITFLOW_REGISTRY_DB_USERNAME
PITFLOW_REGISTRY_DB_PASSWORD
PITFLOW_REGISTRY_DB_HOST
PITFLOW_REGISTRY_DB_PORT

PITFLOW_PAYMENT_DB_NAME
PITFLOW_PAYMENT_DB_USERNAME
PITFLOW_PAYMENT_DB_PASSWORD
PITFLOW_PAYMENT_DB_HOST
PITFLOW_PAYMENT_DB_PORT

PITFLOW_ORCHESTRATOR_TABLE_NAME
PITFLOW_ORCHESTRATOR_AWS_REGION

JWT_SECRET
MOCK_MESSAGE
MAIL_USERNAME
MAIL_PASSWORD
DATADOG_API_KEY
```

Na primeira execução, os hosts são inicializados como string vazia e as portas
como `5432`. O bootstrap usa atribuição condicional para esses campos: valores
já publicados pelo `pitflow-database` são preservados.

As chaves genéricas antigas `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`
e `DB_PORT` são removidas pelo merge.

## GitHub Secrets necessários

Credenciais dos bancos:

```text
PITFLOW_OPERATION_DB_USERNAME
PITFLOW_OPERATION_DB_PASSWORD
PITFLOW_INVENTORY_DB_USERNAME
PITFLOW_INVENTORY_DB_PASSWORD
PITFLOW_REGISTRY_DB_USERNAME
PITFLOW_REGISTRY_DB_PASSWORD
PITFLOW_PAYMENT_DB_USERNAME
PITFLOW_PAYMENT_DB_PASSWORD
```

Configurações compartilhadas:

```text
JWT_SECRET
MOCK_MESSAGE
MAIL_USERNAME
MAIL_PASSWORD
DATADOG_API_KEY
```

Autenticação na AWS:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

`AWS_SESSION_TOKEN` é necessário quando as credenciais AWS são temporárias.
Todos os valores sensíveis são passados pelo contexto `${{ secrets.NOME }}` do
GitHub Actions e não são impressos pelo workflow.

## Valores padronizados

O workflow define:

| Chave | Valor |
| --- | --- |
| `PITFLOW_OPERATION_DB_NAME` | `pitflow-operation-db` |
| `PITFLOW_INVENTORY_DB_NAME` | `pitflow-inventory-db` |
| `PITFLOW_REGISTRY_DB_NAME` | `pitflow-registry-db` |
| `PITFLOW_PAYMENT_DB_NAME` | `pitflow-payment-db` |
| `PITFLOW_*_DB_PORT` | `5432`, somente quando ausente |
| `PITFLOW_ORCHESTRATOR_TABLE_NAME` | `pitflow-orchestrator` |
| `PITFLOW_ORCHESTRATOR_AWS_REGION` | `us-east-1` |

## Execução pelo GitHub Actions

O workflow `.github/workflows/main.yml` executa em pushes para `main` ou
manualmente por `workflow_dispatch`.

1. Cria o bucket de state caso ele ainda não exista.
2. Executa `terraform fmt`, `validate`, `plan` e `apply`.
3. Valida se todos os GitHub Secrets obrigatórios foram configurados.
4. Lê o JSON atual do Secrets Manager.
5. Mescla apenas as chaves pertencentes ao bootstrap e inicializa host/porta
   somente quando ainda não existem.
6. Publica uma nova versão do secret sem registrar seu conteúdo nos logs.

O principal da AWS usado pelo workflow precisa de acesso ao bucket de state e
das permissões necessárias para criar, descrever, ler e publicar versões em
`pitflow/bootstrap`.

## Execução local do Terraform

Configure credenciais AWS e execute:

É necessário Terraform `>= 1.7.0` por causa do bloco `removed` usado na
migração segura da versão antiga.

```bash
cd infra/terraform
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=main.tfplan
terraform apply main.tfplan
terraform output secret_pitflow_name
```

O merge do conteúdo do secret pertence ao workflow. Uma execução local do
Terraform cria ou atualiza somente o recurso `aws_secretsmanager_secret`.

## Segurança

- Não grave credenciais em `terraform.tfvars` ou no repositório.
- Não imprima o JSON atual ou o arquivo temporário criado pelo workflow.
- O arquivo temporário é removido ao término do passo, inclusive em falhas.
- Cada produtor deve ler e mesclar o JSON existente em vez de substituir todas
  as chaves.
- Restrinja `secretsmanager:GetSecretValue` e
  `secretsmanager:PutSecretValue` ao secret `pitflow/bootstrap`.
