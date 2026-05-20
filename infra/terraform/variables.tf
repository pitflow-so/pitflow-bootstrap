variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "mock_message" {
  type      = string
  sensitive = true
}

variable "mail_username" {
  type      = string
  sensitive = true
}

variable "mail_password" {
  type      = string
  sensitive = true
}
