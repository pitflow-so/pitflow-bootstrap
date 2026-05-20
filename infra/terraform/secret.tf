resource "aws_secretsmanager_secret" "secret_pitflow" {
  name = "pitflow/bootstrap"
}

resource "aws_secretsmanager_secret_version" "secret_pitflow_values" {
  secret_id = aws_secretsmanager_secret.secret_pitflow.id

  secret_string = jsonencode({
    DB_PASSWORD   = var.db_password
    DB_USERNAME   = var.db_username
    DB_NAME       = var.db_name
    DB_HOST       = var.db_host
    DB_PORT       = var.db_port
    JWT_SECRET    = var.jwt_secret
    MOCK_MESSAGE  = var.mock_message
    MAIL_USERNAME = var.mail_username
    MAIL_PASSWORD = var.mail_password
  })
}
