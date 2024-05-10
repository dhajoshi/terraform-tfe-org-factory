variable "organization_name" {
  type        = string
  description = "(Required) Name of organization to use for resource management."
}

variable "project_name" {
  type        = string
  description = "(Required) Name of organization to use for resource management."
}

variable "create_new_project" {
  type        = bool
  description = "(Optional) Whether to create a new organization or use an existing one. Defaults to false."
  default     = false
}

variable "create_new_organization" {
  type        = bool
  description = "(Optional) Whether to create a new organization or use an existing one. Defaults to false."
  default     = false
}

variable "organization_email" {
  type        = string
  description = "(Optional) Email of owner for organization. **Required** when creating new organization."
  default     = ""
}

variable "config_file_path" {
  description = "(Required) Path to JSON file holding organization configuration. See example JSON file in documentation for more information."
  type        = string
}

variable "project_name_new" {
  type        = string
  description = "(Required) Name of organization to use for resource management."
  default     = "dj_test_project"
}