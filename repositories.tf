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
  required_approvals  = 2
  required_status_checks = [
    { context = "pre-commit", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]

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
  # Merged into osac mono-repo (OSAC-1732/OSAC-1733); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
    { context = "e2e-vmaas-full-install / e2e", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]
  push_allowances         = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments            = [{ name = "e2e-test" }]
  pages = {
    build_type = "workflow"
    source = {
      branch = "main"
      path   = "/"
    }
  }
}

module "repo_osac" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac"
  description = "OSAC mono-repo: consolidates fulfillment-service, osac-operator, osac-aap, and osac-installer"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    },
    {
      team_id    = "infrastructure"
      permission = "push"
    }
  ]
  # Prow plugins handle approval via OWNERS (lgtm/approved labels), not native
  # GitHub reviews. The label-gate workflow enforces label presence as a status
  # check for the merge queue.
  required_approvals = null
  required_status_checks = [
    { context = "e2e-vmaas-gate", integration_id = 15368 },
    { context = "e2e-bmaas-gate", integration_id = 15368 },
    { context = "e2e-caas-gate", integration_id = 15368 },
    # Reads Prow-set labels (lgtm, approved, jira/valid-reference) and converts
    # them to a status check the merge queue can gate on.
    { context = "check-labels", integration_id = 15368 },
    # Names match GitHub Actions job `name:` (or job id if unnamed). Job-level
    # `if:` skips report success, so docs-only PRs are not blocked.
    { context = "pre-commit", integration_id = 15368 },
    { context = "Check generated code (proto)", integration_id = 15368 },
    { context = "Run unit tests", integration_id = 15368 },
    { context = "Run unit tests (osac-metering)", integration_id = 15368 },
    { context = "Run unit tests (osac-metering/adapters)", integration_id = 15368 },
    { context = "Run unit tests (osac-metering/schema)", integration_id = 15368 },
    { context = "Run integration test (fulfillment-service)", integration_id = 15368 },
    { context = "Run integration test (osac-operator)", integration_id = 15368 },
    { context = "Run integration test (osac-aap)", integration_id = 15368 },
    { context = "Run integration test (osac-installer)", integration_id = 15368 },
    { context = "Run integration test (bare-metal-fulfillment-operator)", integration_id = 15368 },
    # Cheap lints and component unit tests. Step skip reports success when
    # that path did not change, so unrelated PRs are not blocked.
    { context = "ansible-lint", integration_id = 15368 },
    { context = "Check Python code", integration_id = 15368 },
    { context = "Check Go and proto code", integration_id = 15368 },
    { context = "Build binaries", integration_id = 15368 },
    { context = "dependency-review", integration_id = 15368 },
    { context = "Lint Helm charts (osac-installer)", integration_id = 15368 },
    { context = "Check Helm CRD sync (osac-operator)", integration_id = 15368 },
    { context = "Check Helm CRD sync (bare-metal-fulfillment-operator)", integration_id = 15368 },
    { context = "Run darwin keychain tests", integration_id = 15368 },
    { context = "Run unit tests (osac-operator)", integration_id = 15368 },
    { context = "Run unit tests (bare-metal-fulfillment-operator)", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [
    github_team.all["wg-infra"].id,
    github_team.all["infrastructure"].id,
  ]

  merge_queue = {
    merge_method                      = "SQUASH"
    max_entries_to_build              = 4
    max_entries_to_merge              = 5
    min_entries_to_merge              = 1
    min_entries_to_merge_wait_minutes = 5
    check_response_timeout_minutes    = 120
    grouping_strategy                 = "ALLGREEN"
  }
}

module "repo_cloudkit_operator" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-operator"
  description = "OSAC kubernetes operator"
  # Merged into osac mono-repo (OSAC-1732/OSAC-1733); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
    { context = "e2e-vmaas-full-install / e2e", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]
  push_allowances         = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments            = [{ name = "e2e-test" }]
}

module "repo_cloudkit_aap" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-aap"
  description = "OSAC AAP configuration and playbooks"
  # Merged into osac mono-repo (OSAC-1732/OSAC-1733); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
    { context = "e2e-vmaas-full-install / e2e", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]
  push_allowances         = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments            = [{ name = "e2e-test" }]
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
  # Merged into osac mono-repo (OSAC-1732/OSAC-1733); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
    { context = "e2e-vmaas-full-install / e2e", integration_id = 15368 },
  ]

  required_approvals      = null
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]
  push_allowances         = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments            = [{ name = "e2e-test" }]
}

module "repo_enhancement_proposals" {
  source                 = "./modules/common_repository"
  visibility             = "public"
  name                   = "enhancement-proposals"
  description            = "A repository for proposing enhancements to the osac project"
  all_members_permission = "push"
  required_approvals     = 2
  required_status_checks = [
    # Job id in enhancement-proposals/.github/workflows/review-gate.yml.
    { context = "check-human-reviews", integration_id = 15368 },
    # Job id in enhancement-proposals/.github/workflows/pre-commit.yaml.
    { context = "pre-commit", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [github_team.all["wg-infra"].id]
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
    },
    {
      team_id    = "infrastructure"
      permission = "push"
    }
  ]
  required_approvals = null
  required_status_checks = [
    { context = "e2e-vmaas-gate", integration_id = 15368 },
    { context = "e2e-bmaas-gate", integration_id = 15368 },
    { context = "e2e-caas-gate", integration_id = 15368 },
    { context = "check-labels", integration_id = 15368 },
    # Job name in osac-test-infra/.github/workflows/pre-commit.yaml.
    # That workflow must listen to merge_group or the queue waits
    # check_response_timeout_minutes for a check that never reports.
    { context = "pre-commit", integration_id = 15368 },
  ]
  ruleset_bypass_team_ids = [
    github_team.all["wg-infra"].id,
    github_team.all["infrastructure"].id,
  ]
  environments = [{ name = "e2e-test" }]

  merge_queue = {
    merge_method                      = "SQUASH"
    max_entries_to_build              = 4
    max_entries_to_merge              = 5
    min_entries_to_merge              = 1
    min_entries_to_merge_wait_minutes = 5
    check_response_timeout_minutes    = 120
    grouping_strategy                 = "ALLGREEN"
  }
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

module "repo_osac_ux" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-ux"
  description = "OSAC UX Roadmap Console"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    }
  ]
  users = [
    {
      username   = "liatb-rh"
      permission = "admin"
    }
  ]
  pages = {
    build_type = "legacy"
    source = {
      branch = "0.1"
      path   = "/"
    }
  }
}

module "repo_host_management_openstack" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "host-management-openstack"
  description = "[Archived] OSAC Host Management Operator for OpenStack"
  # archived (OSAC-3445)
  archived    = true
  lock_branch = true
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
  # Merged into osac mono-repo (OSAC-1732/OSAC-3395); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
  push_allowances = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
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

module "repo_cluster_tool" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "cluster-tool"
  description = "Instant OpenShift SNO clusters from snapshots, distributed as OCI images"
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
  push_allowances = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
}

module "repo_osac_csi_driver" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-csi-driver"
  description = "OSAC CSI driver for persistent storage"
  # Merged into osac mono-repo (OSAC-1732/OSAC-3530); archived (OSAC-1737).
  archived    = true
  lock_branch = true
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
  push_allowances    = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments       = [{ name = "e2e-test" }]
}

module "repo_osac_metering" {
  source      = "./modules/common_repository"
  visibility  = "public"
  name        = "osac-metering"
  description = "OSAC metering service, installation chart and provider adapters"
  teams = [
    {
      team_id    = "fulfillment-wg"
      permission = "push"
    },
    {
      team_id    = "observability-wg"
      permission = "push"
    },
    {
      team_id    = "wg-infra"
      permission = "admin"
    }
  ]
  required_approvals = null
  push_allowances    = ["/openshift-merge-robot", "osac-project/wg-infra", "osac-project/org-admins"]
  environments       = [{ name = "e2e-test" }]
}

moved {
  from = module.repo_osac_metering_service
  to   = module.repo_osac_metering
}
