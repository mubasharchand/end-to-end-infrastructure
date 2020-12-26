
variable "subscription_id" {
  description = "Azure subscription_id"
  
}

variable "tenant_id" {
  description = "Azure tenant_id"
  
}

variable "client_secret" {
  description = "Azure client_secret"
  
}

variable "client_id" {
  description = "Azure client_id"
  
}

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "iaac"
}

variable "location" {
  description = "The region where the virtual network is created."
  default     = "eastus"
}
