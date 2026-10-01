resource "github_organization_settings" "osac-project" {
  name                                         = "Open Sovereign AI Cloud"
  description                                  = "Self service deployment of OpenShift clusters, virtual machines, and bare metal hosts"
  billing_email                                = "lars@redhat.com"
  secret_scanning_enabled_for_new_repositories = true
  has_repository_projects                      = false

  members_can_create_private_repositories = false
  members_can_create_public_repositories  = false
  members_can_create_repositories         = false
}

# Lets wg-infra manage self-hosted runners/runner groups at the org level
# (register/remove runners, create runner groups, control repo access to
# them) without granting full org-owner access. base_role defaults to
# "none", so this role carries only the permission listed below.
resource "github_organization_role" "runner_manager" {
  name        = "runner-manager"
  description = "Manage organization self-hosted runners and runner groups"

  permissions = [
    "write_organization_runners_and_runner_groups",
  ]
}

# Let the infrastructure team manage Actions environments in the osac
# repository while retaining write access to its code. GitHub's
# manage-environments permission also includes environment secrets and
# variables.
resource "github_organization_repository_role" "osac_environment_manager" {
  name        = "osac-environment-manager"
  description = "Write access plus GitHub Actions environment management for osac"
  base_role   = "write"

  permissions = [
    "manage_environments",
  ]
}

resource "github_organization_role_team" "runner_manager_wg_infra" {
  role_id   = github_organization_role.runner_manager.role_id
  team_slug = github_team.all["wg-infra"].slug
}

# Assign GitHub's predefined "CI/CD admin" organization role to the infrastructure
# team. It grants admin access to Actions policies, runners, runner groups, hosted
# compute network configs, secrets, variables, and usage metrics for the org -- a
# superset of the runner-manager role above -- without granting org-owner access.
data "github_organization_roles" "all" {}

locals {
  # Predefined roles are returned with source = "Predefined". The API's exact
  # spelling for this role's `name` isn't documented (GitHub's own docs example
  # for the analogous "security manager" role uses the slug "security_manager"),
  # so match the known spellings exactly rather than with a loose regex. If the
  # lookup comes back empty, get the real value and pin role_id directly:
  #   gh api /orgs/osac-project/organization-roles --jq '.roles[] | select(.source=="Predefined") | {id, name}'
  cicd_admin_role_names = ["CI/CD admin", "cicd_admin", "ci_cd_admin"]

  cicd_admin_role_id = one([
    for r in data.github_organization_roles.all.roles : r.role_id
    if r.source == "Predefined" && contains(local.cicd_admin_role_names, r.name)
  ])
}

resource "github_organization_role_team" "cicd_admin_infrastructure" {
  role_id   = local.cicd_admin_role_id
  team_slug = github_team.all["infrastructure"].slug
}
