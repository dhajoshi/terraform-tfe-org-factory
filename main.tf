# Create an organization depending on var.create_new_organization
resource "tfe_organization" "org" {
  count = var.create_new_organization ? 1 : 0
  name  = var.organization_name
  email = var.organization_email
}

locals {

  # Set the organization name depending on whether its a new org or existing
  organization_name = var.create_new_organization ? tfe_organization.org[0].id : var.organization_name

  # Import org data from json file
  org_data = jsondecode(file("${var.config_file_path}"))

  # Try to extract the workspace data
  raw_workspaces = try(local.org_data.workspaces, [])

  # Try to extract the project data
  raw_projects = try(local.org_data.projects, [])

  # Normalize the Project data
  projects = [for project in local.raw_projects : {
    name        = project["name"]
    description = try(project["descripton"], "No description provided.")
    teams       = try(project["teams"], [])
  }]

  # Create a list of project access entries
  project_team_access = flatten([
    for project in local.projects : [
      for team in project["teams"] : {
        project_name = project["name"]
        team_name    = team["name"]
        access_level = team["access_level"]
      }
    ]
  ])

  # Normalize the workspace data, at the very least it needs to have a name
  workspaces = [for workspace in local.raw_workspaces : {
    name                = workspace["name"]
    description         = try(workspace["description"], "No description provided.")
    teams               = try(workspace["teams"], [])
    terraform_version   = try(workspace["terraform_version"], "~> 1.0")
    tag_names           = try(workspace["tag_names"], [])
    auto_apply          = try(workspace["auto_apply"], false)
    allow_destroy_plan  = try(workspace["auto_apply"], true)
    execution_mode      = try(workspace["execution_mode"], "remote")
    speculative_enabled = try(workspace["speculative_enabled"], true)
    vcs_repo            = try(workspace["vcs_repo"], {})
    project_id          = try(workspace["project_id"], "prj-GMQmXHMWyhe46heo")
  }]


  #Create a list of workspace access entries
  workspace_team_access = flatten([
    for workspace in local.workspaces : [
      for team in workspace["teams"] : {
        workspace_name = workspace["name"]
        team_name      = team["name"]
        access_level   = team["access_level"]
      }
    ]
  ])

  # Try to extract the team data
  raw_teams = try(local.org_data.teams, [])

  # Normalize the teams data, each team at least needs a name
  teams = [for team in local.raw_teams : {
    name                = team["name"]
    visibility          = try(team["visibility"], "secret")
    organization_access = try(team["organization_access"], {})
    members             = try(team["members"], [])
  }]


}

# Use a dedicated project for this workspace
resource "tfe_project" "myproject" {
  for_each     = { for project in local.projects : project["name"] => project }
  organization = local.organization_name
  name         = each.key
  description  = each.value["description"]
}


# Check for project exist
#data "tfe_project" "tfeproject" {
#   for_each = { for project in local.projects : project["name"] => project }
#   name = "dj_test_project"
#   organization = local.organization_name
#}


# Create workspaces
resource "tfe_workspace" "workspaces" {
  # Create a map of workspaces from the list stored in JSON using the
  # workspace name as the key
  for_each            = { for workspace in local.workspaces : workspace["name"] => workspace }
  name                = each.key
  description         = each.value["description"]
  terraform_version   = each.value["terraform_version"]
  organization        = local.organization_name
  tag_names           = each.value["tag_names"]
  auto_apply          = each.value["auto_apply"]
  allow_destroy_plan  = each.value["allow_destroy_plan"]
  execution_mode      = each.value["execution_mode"]
  speculative_enabled = each.value["speculative_enabled"]
  project_id          = each.value["project_id"]
 # oauth_token_id      = var.oauth_token_id

  # Create a single vcs_repo block if value isn't an empty map
  dynamic "vcs_repo" {
    for_each = each.value["vcs_repo"] != {} ? toset(["1"]) : toset([])

    content {
      identifier     = each.value.vcs_repo["identifier"]
      oauth_token_id = var.oauth_token_id
  #    oauth_token_id = each.value.vcs_repo["oauth_token_id"]
    }
  }
}

/*
# Create teams
resource "tfe_team" "teams" {
  # Create a map of teams from the list stored in JSON using the 
  # team name as the key
  for_each     = { for team in local.teams : team["name"] => team }
  name         = each.key
  organization = local.organization_name
  visibility   = each.value["visibility"]

  # Create a single organization_access block if value isn't an empty map
  dynamic "organization_access" {
    for_each = each.value["organization_access"] != {} ? toset(["1"]) : toset([])

    content {
      # Get the value for each permission if it exists, set to false if it doesn't
      manage_policies         = try(each.value.organization_access["manage_policies"], false)
      manage_policy_overrides = try(each.value.organization_access["manage_policy_overrides"], false)
      manage_workspaces       = try(each.value.organization_access["manage_workspaces"], false)
      manage_vcs_settings     = try(each.value.organization_access["manage_vcs_settings"], false)
    }
  }
}
*/

data "tfe_team" "teams" {
  for_each     = { for team in local.teams : team["name"] => team }
  name         = each.key
  organization = local.organization_name
}

# Configure workspace access for teams
resource "tfe_team_access" "team_access" {
  for_each     = { for access in local.workspace_team_access : "${access.workspace_name}_${access.team_name}" => access }
  access       = each.value["access_level"]
  team_id      = data.tfe_team.teams[each.value["team_name"]].id
  #team_id      = tfe_team.teams[each.value["team_name"]].id
  workspace_id = tfe_workspace.workspaces[each.value["workspace_name"]].id
}

# Configure Project access for teams
resource "tfe_team_project_access" "project_team_access" {
  for_each    = { for access in local.project_team_access : "${access.project_name}_${access.team_name}" => access }
  access      = each.value["access_level"]
  team_id     = tfe_team.teams[each.value["team_name"]].id
  project_id  = tfe_project.myproject[each.value["project_name"]].id
}

# Add TFC accounts to the organization
resource "tfe_organization_membership" "org_members" {
  for_each     = toset(flatten(local.teams.*.members))
  organization = local.organization_name
  email        = each.value
}

locals {
  # Create a list of member mappings like this
  # team_name = team_name
  # member_name = member_email
  team_members = flatten([
    for team in local.teams : [
      for member in team["members"] : {
        team_name   = team["name"]
        member_name = member
      } if length(team["members"]) > 0
    ]
  ])
}

resource "tfe_team_organization_member" "team_members" {
  # Create a map with the team name and member name combines as a key for uniqueness
  for_each                   = { for member in local.team_members : "${member.team_name}_${member.member_name}" => member }
  team_id                    = tfe_team.teams[each.value["team_name"]].id
  organization_membership_id = tfe_organization_membership.org_members[each.value["member_name"]].id
}
