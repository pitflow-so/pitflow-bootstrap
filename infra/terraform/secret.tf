resource "aws_secretsmanager_secret" "secret_pitflow" {
  name        = "pitflow/bootstrap"
  description = "Shared bootstrap configuration for Pitflow services"
}
