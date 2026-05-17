resource "aws_secretsmanager_secret" "secret_pitflow" {
  name = "pitflow/bootstrap"
}

resource "aws_secretsmanager_secret_version" "secret_pitflow_values" {
  secret_id = aws_secretsmanager_secret.secret_pitflow.id

  secret_string = jsonencode({
    DB_PASSWORD   = var.db_password
    JWT_SECRET    = var.jwt_secret
    MOCK_MESSAGE  = var.mock_message
    MAIL_USERNAME = var.mail_username
    MAIL_PASSWORD = var.mail_password
  })
}
