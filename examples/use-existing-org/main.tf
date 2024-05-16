# Configure existing organization with module
module "tfe_workspace" {
  source = "../.."

  organization_name = var.organization_name
  config_file_path  = var.config_file_path
  oauth_token_id = var.oauth_token_id
}