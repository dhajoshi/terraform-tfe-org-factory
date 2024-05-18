terraform {

  required_version = ">= 1.8.2"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.54.0"
    }
  }
}

locals {
  myproject = [ {
    "name": "Default Project"
  },
  {
    "name": "dj_test_project"
  }]
}

data "tfe_project" "projects" {
  for_each     = { for team in local.myproject : team["name"] => team }
  name         = each.key
  organization = "dhajoshi-infra"
}

output "projectname" {
   #value = {
   # for project_id, instance in data.tfe_project.projects :
   #   project_id => {
   #   id = instance.id
   #   name  = instance.name
   #   # more attributes as needed
   # }
 # }
 # for_each     = { for team in local.myproject : team["name"] => team }
 value        = data.tfe_project.projects
}