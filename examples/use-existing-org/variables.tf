variable "organization_name" {
  type        = string
  description = "(Required) Name of existing organization to manage."
  default     = "dhajoshi-infra"
}

variable "config_file_path" {
  type        = string
  description = "(Optional) Path of JSON config file. Defaults to basic_config.json"
  default     = "basic_config.json"
}

variable "project_name_new" {
  type        = string
  description = "(Required) Name of organization to use for resource management."
  default     = "dj_test_project"
}

variable "oauth_token_id" {
  type        = string
  description = "(Required) Auth token for VCS Connection"
  sensitive   =  true
}