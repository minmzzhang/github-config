module "repo_issues" {
  source                 = "./modules/common_repository"
  name                   = "issues"
  visibility             = "public"
  description            = "Issues related to AI in a Box project"
  use_public_template    = false
  all_members_permission = "push"
}

module "repo_docs" {
  source                 = "./modules/common_repository"
  name                   = "docs"
  description            = "General documentation for the AI in a Box project"
  use_public_template    = false
  all_members_permission = "push"

  teams = [
    {
      team_id    = "documentation-wg"
      permission = "push"
    }
  ]
}

module "repo_dotgithub" {
  source              = "./modules/common_repository"
  name                = ".github"
  description         = "Profile README for osac-project organization"
  use_public_template = false
}

module "repo_github_config" {
  source              = "./modules/common_repository"
  name                = "github-config"
  description         = "Repository for managing osac-project github organization"
  use_public_template = false
  required_status_checks = [
    "pre-commit",
  ]

  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_dotgithub_private" {
  source      = "./modules/common_repository"
  visibility  = "private"
  name        = ".github-private"
  description = "Member-only README for osac-project organization"
}

module "repo_public_template" {
  source              = "./modules/common_repository"
  visibility          = "public"
  name                = "public_template"
  description         = "Use this repository as the template for public-facing repositories"
  use_public_template = false
  is_template         = true
}

module "repo_managed_cluster_config" {
  source              = "./modules/common_repository"
  visibility          = "public"
  name                = "managed-cluster-config"
  use_public_template = false
  description         = "Configuration for OpenShift cluster running ACM w/ Hosted Control Planes"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_managed_cluster_apps" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "managed-cluster-apps"
  description = "Argocd apps to deploy resources on the innabox cluster"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_fulfillment_service" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "fulfillment-service"
  description = "Cloud-in-a-box fulfillment service"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]
  required_approvals = null
  required_status_checks = [
    "ci/prow/unit"
  ]
  push_allowances = ["/openshift-merge-robot", "osac-project/wg-infra"]
  pages = {
    build_type = "workflow"
    source = {
      branch = "main"
      path   = "/"
    }
  }
}

module "repo_cloudkit_operator" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-operator"
  description = "OSAC kubernetes operator"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]

  required_status_checks = [
    "ci/prow/temp"
  ]

  required_approvals = null
  push_allowances    = ["/openshift-merge-robot", "osac-project/wg-infra"]
}

module "repo_cloudkit_aap" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-aap"
  description = "OSAC AAP configuration and playbooks"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]
  required_approvals = null
  required_status_checks = [
    "ci/prow/temp"
  ]
  push_allowances = ["/openshift-merge-robot", "osac-project/wg-infra"]
}

module "repo_cloudkit_aap_ee" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-aap-ee"
  description = "OSAC execution environment for AAP"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_cloudkit_operator_config" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-operator-config"
  description = "Configuration for our deployment of the OSAC operator"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_osac_installer" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-installer"
  description = "Integration repository for installing all OSAC components"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]

  required_status_checks = [
    "ci/prow/temp",
    "ci/prow/images"
  ]

  required_approvals = null
  push_allowances    = ["/openshift-merge-robot", "osac-project/wg-infra"]
}

module "repo_enhancement_proposals" {
  source                 = "./modules/common_repository"
  visibility             = "public"
  name                   = "enhancement-proposals"
  description            = "A repository for proposing enhancements to the osac project"
  all_members_permission = "push"
  required_approvals     = 2
}

module "repo_osac_test_infra" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-test-infra"
  description = "Ansible-based test infrastructure for OSAC end-to-end testing"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]
  required_approvals = null
  required_status_checks = [
    "ci/prow/temp"
  ]
  push_allowances = ["/openshift-merge-robot", "osac-project/wg-infra"]
}

module "repo_massopencloud_templates" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-massopencloud-templates"
  description = "OSAC MOC-specific templates"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_osac_ui" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-ui"
  description = "OSAC UI Web Console"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_host_management_openstack" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "host-management-openstack"
  description = "OSAC Host Management Operator for OpenStack"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_bare_metal_operator" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "bare-metal-fulfillment-operator"
  description = "OSAC Operator for Bare Metal Fulfillment"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
}

module "repo_osac_workspace" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-workspace"
  description = "Workspace for operating on OSAC repositories with AI tooling"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
  pages = {
    build_type = "workflow"
    source = {
      branch = "main"
      path   = "/"
    }
  }
}
