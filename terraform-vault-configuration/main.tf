terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      # version = "2.15.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "2.36.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  features {}
}


provider "vault" {
  # Configuration options
}

resource "vault_auth_backend" "example" {
  type = "userpass"
}

resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin_policy.hcl")
}

resource "vault_policy" "developer_policy" {
  name   = "developers"
  policy = file("policies/developer_policy.hcl")
}

resource "vault_policy" "operations_policy" {
  name   = "operations"
  policy = file("policies/operation_policy.hcl")
}

resource "vault_mount" "developers" {
  path        = "developers"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Developers."
}

resource "vault_mount" "operations" {
  path        = "operations"
  type        = "kv-v2"
  description = "KV2 Secrets Engine for Operations."
}

resource "vault_generic_secret" "developer_sample_data" {
  path = "${vault_mount.developers.path}/test_account"

  data_json = <<EOT
{
  "username": "foo",
  "password": "bar"
}
EOT
}
# Azure Secrets Engine Configuration
resource "azurerm_resource_group" "myresourcegroup" {
  name     = "${var.prefix}-jenkins"
  location = var.location

  tags = local.common_tags
}

resource "vault_azure_secret_backend" "azure" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_secret = var.client_secret
  client_id = var.client_id
}

resource "vault_azure_secret_backend_role" "jenkins" {
  backend                     = vault_azure_secret_backend.azure.path
  role                        = "jenkins"
  ttl                         = "24h"
  max_ttl                     = "48h"

  azure_roles {
    role_name = "Contributor"
    scope =  "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.myresourcegroup.name}"
  }
}

# Jenkins Secure Introduction

resource "vault_policy" "pipeline_policy" {
  name = "pipeline-policy"
  policy = file("policies/jenkins_pipeline_policy.hcl")
}

resource "vault_policy" "jenkins_policy" {
  name = "jenkins-policy"
  policy = file("policies/jenkins_policy.hcl")
}

resource "vault_auth_backend" "jenkins_access" {
  type = "approle"
  path = "jenkins"
}

resource "vault_approle_auth_backend_role" "jenkins_approle" {
  backend            = vault_auth_backend.jenkins_access.path
  role_name          = "jenkins-approle"
  //secret_id_num_uses = "0"  means unlimited 
  secret_id_num_uses = "0" 
  token_policies     = ["default", "jenkins-policy"]
}

resource "vault_auth_backend" "pipeline_access" {
  type = "approle"
  path = "pipeline"
}

resource "vault_approle_auth_backend_role" "pipeline_approle" {
  backend            = vault_auth_backend.pipeline_access.path
  role_name          = "pipeline-approle"
  secret_id_num_uses = "1"
  secret_id_ttl      = "300"
  token_ttl          = "1800"
  token_policies     = ["default", "pipeline-policy"]
}

resource "vault_auth_backend" "apps_access" {
  type = "approle"
  path = "approle"
}

resource "vault_approle_auth_backend_role" "web_app_approle" {
  backend            = vault_auth_backend.apps_access.path
  role_name          = "web_app-approle"
  secret_id_num_uses = "1"
  secret_id_ttl      = "600"
  token_ttl          = "1800"
  token_policies     = ["default", "webblog"]
}
