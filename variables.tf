# Azure RM
variable "account_azure_subscription_id" {}
variable "account_azure_client_id" {}
variable "account_azure_client_secret" {}
variable "account_azure_tenant_id" {}

# General Variables
variable "resource_group_name" { default = "Giacomo-Quaglia-001" }
variable "name_prefix" { default = "giacomo-quaglia" }
variable "region" { default = "North Europe" }