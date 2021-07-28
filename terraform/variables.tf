variable "eventrouter_rg" {
  type = string
}

variable "eventrouter_location" {
  type = string
}

variable "prefix" {
  type = string
  validation {
    condition     = length(var.prefix) <= 14
    error_message = "The prefix value must be 14 characters or less."
  }
}

variable "appinsights_ikey" {
  type      = string
  default   = null
  sensitive = true
}

variable "github_create_issue_target" {
  type = object({
    owner = string
    repo  = string
    token = string
  })
  sensitive = true
}

variable "github_eventrouter" {
  type = object({
    repo  = string
    token = string
  })
  sensitive = true
}

variable "azure_credentials" {
  type = object({
    subscription_id = string
    tenant_id       = string
    client_id       = string
    client_secret   = string
  })
  sensitive = true
}
