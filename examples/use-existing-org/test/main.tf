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

locals {
  variable_set = [ "varset1",
                   "varset2"
   ]
}

resource "tfe_variable_set" "set" {
  for_each = toset(local.variable_set)
  name     = each.key
  organization = "dhajoshi-infra"
}

data "tfe_variable_set" "searchset" {
  for_each = toset(local.variable_set)
  name     = each.key
  organization = "dhajoshi-infra"
  depends_on = [ tfe_variable_set.set ]
}

locals {
  variables = {
       "AWS_REGION": {
            "category": "env",
            "description": "AWS Region",
            "sensitive": false,
            "hcl": false,
            "value": "ap-south-1",
            "variable_set": "varset1"
        },
        "aws_tag_owner": {
            "category": "terraform",
            "description": "Owner of all resources",
            "sensitive": false,
            "hcl": false,
            "value": "d.joshi84@gmail.com",
            "variable_set": "varset2"
        },
        "new_variable": {
            "category": "terraform",
            "description": "Owner of all resources",
            "sensitive": false,
            "hcl": false,
            "value": "d.joshi84@gmail.com",
            "variable_set": "varset2"
        }
  }
}

resource "tfe_variable" "var"{
  for_each = local.variables
  key = each.key
  value           = each.value.hcl ? replace(jsonencode(each.value.value), "/\"(\\w+?)\":/", "$1=") : try(tostring(each.value.value), null)
  category        = each.value.category
  hcl             = each.value.hcl
  variable_set_id = data.tfe_variable_set.searchset[each.value.variable_set].id
  description     = each.value.description
  sensitive       = each.value.sensitive
}



data "tfe_project" "projects" {
  for_each     = { for team in local.myproject : team["name"] => team }
  name         = each.key
  organization = "dhajoshi-infra"
}

#output "projectname" {
   #value = {
   # for project_id, instance in data.tfe_project.projects :
   #   project_id => {
   #   id = instance.id
   #   name  = instance.name
   #   # more attributes as needed
   # }
 # }
 # for_each     = { for team in local.myproject : team["name"] => team }
 #value        = data.tfe_project.projects
#}