resource "github_repository" "repo" {
  name                        = var.name
  archived                    = var.archived
  visibility                  = var.visibility
  description                 = var.description
  auto_init                   = true
  allow_auto_merge            = var.visibility == "private" ? false : true
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  has_issues                  = true
  has_downloads               = false
  has_projects                = false
  has_wiki                    = false
  is_template                 = var.is_template
  vulnerability_alerts        = var.vulnerability_alerts

  dynamic "template" {
    # Use the public_template repository as a template unless the repository is
    # private or is a template
    for_each = var.visibility == "private" ? [] : var.is_template ? [] : var.use_public_template ? ["enabled"] : []

    content {
      owner      = "osac-project"
      repository = "public_template"
    }
  }

  dynamic "pages" {
    # enable this block if `pages` is not null
    # Skip pages config for archived repos (GitHub rejects it with 409)
    for_each = var.archived ? [] : var.pages[*]

    content {
      cname      = pages.value.cname
      build_type = pages.value.build_type

      dynamic "source" {
        for_each = var.pages.source[*]

        content {
          branch = source.value.branch
          path   = source.value.path
        }
      }
    }
  }
}

resource "github_issue_label" "repo_labels" {
  repository = var.name

  # Generate label blocks from the value of local.values, which by default is initialized
  # by the contents of the "labels.csv" file.
  # Skip labels for archived repos (GitHub rejects writes with 409)
  for_each = var.archived ? {} : {
    for label in local.labels :
    label.name => label
  }

  name        = each.value.name
  color       = each.value.color
  description = each.value.description

  depends_on = [github_repository.repo]
}

resource "github_branch_protection" "repo_protection" {
  # This odd looking construct lets us control the creation of the
  # branch protection resource with a boolean variable, and skip it
  # entirely for archived repos (GitHub rejects writes with 409).
  count = var.visibility == "private" ? 0 : var.archived ? 0 : var.branch_protection ? 1 : 0

  repository_id = var.name
  pattern       = "main"

  required_linear_history         = true
  allows_deletions                = false
  allows_force_pushes             = false
  enforce_admins                  = false
  require_conversation_resolution = false
  require_signed_commits          = false
  lock_branch                     = var.lock_branch

  force_push_bypassers = [
    "osac-project/org-admins",
  ]

  dynamic "restrict_pushes" {
    for_each = var.push_allowances != null ? [1] : []
    content {
      push_allowances = var.push_allowances
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = var.required_approvals[*]

    content {
      required_approving_review_count = var.required_approvals
      require_code_owner_reviews      = var.require_code_owner_reviews
    }
  }


  depends_on = [github_repository.repo, github_repository_collaborators.repo_collaborators]
}

resource "github_repository_ruleset" "status_checks" {
  count = var.visibility == "private" ? 0 : var.archived ? 0 : var.branch_protection && length(var.required_status_checks) > 0 ? 1 : 0

  name        = "ci-status-checks"
  repository  = github_repository.repo.name
  target      = "branch"
  enforcement = "active"

  bypass_actors {
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  # GitHub Merge Queue app — must bypass the ruleset to push rebased
  # commits to the protected branch after queue checks pass.
  dynamic "bypass_actors" {
    for_each = var.merge_queue != null ? [1] : []
    content {
      actor_id    = 262318
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

  dynamic "bypass_actors" {
    for_each = var.ruleset_bypass_team_ids
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Team"
      bypass_mode = "always"
    }
  }

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    # Block direct pushes — require a PR. CHANGES_REQUESTED reviews are
    # auto-dismissed by the auto-queue workflow so they don't block merging.
    dynamic "pull_request" {
      for_each = var.merge_queue != null ? [1] : []
      content {
        required_approving_review_count = 0
      }
    }

    required_status_checks {
      # When merge queue is enabled, strict is unnecessary — the queue tests
      # each PR against latest main before merging.
      strict_required_status_checks_policy = var.merge_queue != null ? false : true

      dynamic "required_check" {
        for_each = var.required_status_checks
        content {
          context        = required_check.value.context
          integration_id = required_check.value.integration_id
        }
      }
    }

    dynamic "merge_queue" {
      for_each = var.merge_queue[*]
      content {
        check_response_timeout_minutes    = merge_queue.value.check_response_timeout_minutes
        grouping_strategy                 = merge_queue.value.grouping_strategy
        max_entries_to_build              = merge_queue.value.max_entries_to_build
        max_entries_to_merge              = merge_queue.value.max_entries_to_merge
        merge_method                      = merge_queue.value.merge_method
        min_entries_to_merge              = merge_queue.value.min_entries_to_merge
        min_entries_to_merge_wait_minutes = merge_queue.value.min_entries_to_merge_wait_minutes
      }
    }
  }

  depends_on = [github_repository.repo]
}

resource "github_repository_ruleset" "tag_creation" {
  for_each = var.archived ? {} : { for r in var.tag_rulesets : r.name => r }

  name        = "${each.value.name}-creation"
  repository  = github_repository.repo.name
  target      = "tag"
  enforcement = "active"

  dynamic "bypass_actors" {
    for_each = each.value.creation_bypass_app_ids
    content {
      actor_id    = bypass_actors.value
      actor_type  = "Integration"
      bypass_mode = "always"
    }
  }

  conditions {
    ref_name {
      include = each.value.ref_patterns
      exclude = []
    }
  }

  rules {
    creation = true
  }

  depends_on = [github_repository.repo]
}

resource "github_repository_ruleset" "tag_immutable" {
  for_each = var.archived ? {} : { for r in var.tag_rulesets : r.name => r }

  name        = "${each.value.name}-immutable"
  repository  = github_repository.repo.name
  target      = "tag"
  enforcement = "active"

  # Deliberately no bypass_actors -- updates/deletions are blocked for
  # everyone, including the App(s) allowed to create matching tags above.

  conditions {
    ref_name {
      include = each.value.ref_patterns
      exclude = []
    }
  }

  rules {
    update   = true
    deletion = true
  }

  depends_on = [github_repository.repo]
}

resource "github_repository_environment" "env" {
  # Skip environments for archived repos (GitHub rejects writes with 409)
  for_each = var.archived ? {} : {
    for env in var.environments :
    env.name => env
  }

  repository  = var.name
  environment = each.value.name

  dynamic "reviewers" {
    for_each = each.value.reviewers != null ? [each.value.reviewers] : []
    content {
      teams = reviewers.value.teams
      users = reviewers.value.users
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_branch_policy != null ? [each.value.deployment_branch_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }

  depends_on = [github_repository.repo]
}

resource "github_repository_collaborators" "repo_collaborators" {
  repository = var.name

  # Always grant org-admins push (write) access to repository. This is necessary to support the
  # force_push_bypassers configuration (above).
  team {
    team_id    = "org-admins"
    permission = "push"
  }

  # Permission for all organization members
  team {
    team_id    = "all-members"
    permission = var.all_members_permission
  }

  # Generate team blocks from the value of the "teams" input variable.
  dynamic "team" {
    for_each = {
      for team in var.teams :
      team.team_id => team
    }
    content {
      team_id    = team.value.team_id
      permission = team.value.permission
    }
  }

  # Generate user blocks from the value of the "users" input variable.
  dynamic "user" {
    for_each = {
      for user in var.users :
      user.username => user
    }
    content {
      username   = user.value.username
      permission = user.value.permission
    }
  }

  depends_on = [github_repository.repo]
}
