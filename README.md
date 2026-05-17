# pitflow-bootstrap

Bootstrap de infraestrutura e base de CI/CD do projeto PITFLOW.

Este repositório concentra a configuração inicial de infraestrutura na AWS usando Terraform e GitHub Actions. <br>
O projeto cria um secret no AWS Secrets Manager para armazenar variáveis sensíveis usadas pela aplicação.

## Componentes principais

### Terraform

Os arquivos Terraform ficam em `infra/terraform`.

- `provider.tf`: define a versão minima do Terraform, o provider AWS e a região.
- `variables.tf`: declara variáveis sensíveis usadas para montar o conteúdo do secret.
- `secret.tf`: cria o recurso `aws_secretsmanager_secret` chamado `pitflow/bootstrap` e grava uma versão do secret com os valores em JSON.
- `outputs.tf`: expõe o nome do secret criado por meio do output `secret_pitflow_name`.
- `backend.tf`: contem a configuração de backend S3 para armazenar o state remoto. Para execução local com state local, comente esse bloco antes de executar `terraform init`.

### GitHub Actions

O workflow `.github/workflows/main.yml` executa em pushes para a branch `main` e também manualmente via `workflow_dispatch`.

Ele possui dois jobs:

1. `bootstrap-s3`: configura credenciais AWS e cria o bucket S3 `tfstate-backend-fiap-pitflow`, caso ele ainda nao exista.
2. `infrastructure`: executa os comandos terraform para criação dos recursos.

## Variáveis de ambiente e secrets

O projeto usa variáveis sensíveis para nao deixar senhas, tokens e dados privados diretamente no código versionado.

As variáveis declaradas no Terraform sao:

| Variável | Uso | Justificativa |
| --- | --- | --- |
| `db_password` | Senha de banco de dados | Dado sensível |
| `jwt_secret` | Chave usada para assinatura/validação de JWT | Dado sensível |
| `mock_message` | Mensagem ou valor de teste sensível | Mantida como secret para permitir troca por ambiente sem alterar código. |
| `mail_username` | Usuário/conta de e-mail | Pode identificar conta de serviço ou integração externa. |
| `mail_password` | Senha da conta de e-mail | Dado sensível |

Na execução local, esses valores devem ser informados em `infra/terraform/terraform.tfvars`.

Na GitHub Action, esses valores vem de GitHub Secrets:

- `DB_PASSWORD`
- `JWT_SECRET`
- `MOCK_MESSAGE`
- `MAIL_USERNAME`
- `MAIL_PASSWORD`

Também sao necessários secrets para autenticação na AWS:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`, quando a credencial utilizada for temporária

## Justificativa do AWS Secrets Manager

O AWS Secrets Manager e usado para centralizar valores sensíveis da aplicação em um serviço próprio para segredos.

Isso evita que senhas e tokens fiquem gravados no repositório, em arquivos de configuração da aplicação ou em logs de deploy. O secret `pitflow/bootstrap` armazena os valores em formato JSON, facilitando o consumo posterior pela aplicação ou por outros recursos AWS.

Conteúdo criado no secret:

```json
{
  "DB_PASSWORD": "...",
  "JWT_SECRET": "...",
  "MOCK_MESSAGE": "...",
  "MAIL_USERNAME": "...",
  "MAIL_PASSWORD": "..."
}
```

## Justificativa do S3 na Action

O bucket S3 `tfstate-backend-fiap-pitflow` e criado no workflow para servir como backend remoto do Terraform state.

O state do Terraform registra os recursos criados e seus identificadores. Guarda-lo em S3 traz benefícios importantes:

- mantém o state fora da maquina local do desenvolvedor;
- permite que a pipeline e outros operadores trabalhem sobre o mesmo estado;
- reduz o risco de perder o state local;
- habilita versionamento do bucket, permitindo recuperar versões anteriores do state em caso de erro.


## Como executar localmente

### Pre-requisitos

- Terraform `>= 1.5.0`
- AWS CLI configurado ou credenciais AWS disponíveis no ambiente
- Permissões AWS para criar e gerenciar Secrets Manager
- Caso use backend S3, permissões para acessar o bucket `tfstate-backend-fiap-pitflow`

### Credenciais AWS

Antes de rodar o Terraform localmente, configure as credenciais da AWS.

Opção com AWS CLI:

```bash
aws configure
```

Opção com variáveis de ambiente:

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_DEFAULT_REGION="us-east-1"
```

No Windows PowerShell:

```powershell
$env:AWS_ACCESS_KEY_ID="..."
$env:AWS_SECRET_ACCESS_KEY="..."
$env:AWS_SESSION_TOKEN="..."
$env:AWS_DEFAULT_REGION="us-east-1"
```

### Criar o arquivo `terraform.tfvars`

Crie ou atualize o arquivo `infra/terraform/terraform.tfvars` com os valores necessários:

```hcl
db_password   = "sua-senha-do-banco"
jwt_secret    = "sua-chave-jwt"
mock_message  = "mensagem"
mail_username = "usuario@email.com"
mail_password = "senha-do-email"
```

Esse arquivo nao deve ser versionado. Ele esta coberto pelo `.gitignore` porque contem dados sensíveis.

### Executar os comandos

Acesse a pasta do Terraform:

```bash
cd infra/terraform
```

Comente o conteúdo do arquivo `backend.tf`

Inicialize o Terraform:

```bash
terraform init
```

Formate os arquivos:

```bash
terraform fmt -recursive
```

Valide a configuração:

```bash
terraform validate
```

Gere o plano:

```bash
terraform plan -out=main.tfplan
```

Aplique a infraestrutura:

```bash
terraform apply main.tfplan
```

Consultar o output:

```bash
terraform output secret_pitflow_name
```

## Execução via GitHub Actions

Para a pipeline funcionar, garanta que as credenciais da AWS estejam atualizadas!

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

Depois disso, a action pode ser executada automaticamente em push para `main` ou manualmente pela aba Actions do GitHub.

## Observações importantes

- Nunca commite o arquivo `terraform.tfvars` com valores reais.
- Para usar state local, comente o bloco de backend em `backend.tf` e rode `terraform init`.
- O secret criado na AWS se chama `pitflow/bootstrap`, e o nome e exposto pelo output `secret_pitflow_name`.
