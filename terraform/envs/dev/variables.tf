variable "project_name" {
  type = string
}

variable "location" {
  type    = string
  default = "East US"
}

variable "subscription_id" {
  type    = string
  default = "0ae910fb-96e8-4318-906a-8763196dc0a5"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "morning-brief"
    environment = "dev"
    managed_by  = "terraform"
  }
}
