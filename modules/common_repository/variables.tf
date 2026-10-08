variable "archived" {
  description = "Whether the repository is archived"
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the repository"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
}

variable "required_approvals" {
  description = "Number of approvals required before merging a pull request"
  type        = number
  default     = 1
}

variable "require_code_owner_reviews" {
  description = "Require an approving review from a code owner (per the repository's CODEOWNERS file) before merging a pull request. Only has an effect when required_approvals is not null."
  type        = bool
  default     = false
}

variable "required_status_checks" {
  description = "Status checks that must pass before a PR can merge"
  type = list(object({
    context        = string
    integration_id = optional(number)
  }))
  default = []
}

variable "visibility" {
  description = "Repository visibility (public or private)"
  type        = string
  default     = "public"
  validation {
    error_message = "unknown visiblity: must be public or private"
    condition     = contains(["public", "private"], var.visibility)
  }
}

variable "branch_protection" {
  description = "Configure branch protection if true"
  type        = bool
  default     = true
}

variable "lock_branch" {
  description = "Make the protected branch read-only, blocking all pushes. Intended for repositories that have been merged into another repo and are pending archival."
  type        = bool
  default     = false
}

variable "labels" {
  description = "List of labels to configure on the repository"
  type = list(object({
    name        = string
    color       = string
    description = string
  }))
  default = null
}

variable "teams" {
  description = "Teams with access to this repository"
  type = list(object({
    team_id    = string
    permission = string
  }))
  default = []
  validation {
    error_message = "unknown permission: permission must be one of pull, push, maintain, triage, or admin"
    condition = alltrue([
      for v in var.teams : contains(["pull", "push", "maintain", "triage", "admin"], v.permission)
    ])
  }
}

variable "users" {
  description = "Users with access to this repository"
  type = list(object({
    username   = string
    permission = string
  }))
  default = []
  validation {
    error_message = "unknown permission: permission must be one of pull, push, maintain, triage, or admin"
    condition = alltrue([
      for v in var.users : contains(["pull", "push", "maintain", "triage", "admin"], v.permission)
    ])
  }
}

variable "is_template" {
  description = "Set this to true if this is a template repository"
  type        = bool
  default     = false
}

variable "use_public_template" {
  description = "Use the public_template repository as the template for a new repository"
  type        = bool
  default     = true
}

variable "vulnerability_alerts" {
  description = "Enable or disable dependabot vulnerability alerts"
  type        = bool
  default     = false
}

variable "pages" {
  description = "Configuration for github pages"
  type = object({
    source = optional(object({
      branch = string
      path   = string
    }))
    build_type = optional(string, "legacy")
    cname      = optional(string)
  })
  default = null

  validation {
    error_message = "build_type must be one of \"workflow\" or \"legacy\""
    condition = var.pages == null ? true : (
      var.pages.build_type == null ||
      contains(["legacy", "workflow"], var.pages.build_type)
    )
  }
}

variable "push_allowances" {
  description = "Actors allowed to push to the protected branch. When set, restricts both direct pushes and PR merges to these actors only. Actor names must begin with '/' for users or 'org-name/' for teams."
  type        = list(string)
  default     = null
  validation {
    condition     = var.push_allowances == null || length(var.push_allowances) > 0
    error_message = "push_allowances must be null (disabled) or a non-empty list of actors"
  }
}

variable "allow_merge_commit" {
  description = "Allow merge commits on pull requests"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merging on pull requests"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merging on pull requests"
  type        = bool
  default     = true
}

variable "environments" {
  description = "GitHub environments to create for this repository"
  type = list(object({
    name = string
    reviewers = optional(object({
      teams = optional(list(string), [])
      users = optional(list(string), [])
    }))
    deployment_branch_policy = optional(object({
      protected_branches     = optional(bool, true)
      custom_branch_policies = optional(bool, false)
    }))
  }))
  default = []

  validation {
    condition     = alltrue([for env in var.environments : trimspace(env.name) != ""])
    error_message = "All environment names must be non-empty strings."
  }

  validation {
    condition     = length(distinct([for env in var.environments : env.name])) == length(var.environments)
    error_message = "Environment names must be unique; duplicates would cause a for_each key collision."
  }
}

variable "ruleset_bypass_team_ids" {
  description = "Team database IDs allowed to bypass the CI status checks ruleset"
  type        = list(number)
  default     = []
}

variable "merge_queue" {
  description = "Merge queue configuration. When set, enables merge queue on the default branch and disables strict status checks (the queue handles freshness)."
  type = object({
    merge_method                      = optional(string, "SQUASH")
    max_entries_to_build              = optional(number, 5)
    max_entries_to_merge              = optional(number, 5)
    min_entries_to_merge              = optional(number, 1)
    min_entries_to_merge_wait_minutes = optional(number, 5)
    check_response_timeout_minutes    = optional(number, 60)
    grouping_strategy                 = optional(string, "ALLGREEN")
  })
  default = null
}

variable "all_members_permission" {
  description = "Permission for all organization members"
  type        = string
  default     = "triage"
  validation {
    error_message = "invalid permission name"
    condition     = contains(["pull", "push", "triage", "maintain", "admin"], var.all_members_permission)
  }
}

variable "tag_rulesets" {
  description = <<-EOT
    Tag protection rulesets. Each entry creates two ruleset resources for the
    given ref patterns: one allowing tag creation only to the listed GitHub
    App IDs (nobody, if left empty), and one blocking tag updates and
    deletions for everyone unconditionally, with no bypass. Intended for
    marker/automation tags that a specific trusted CI identity creates and
    that should otherwise be immutable.
  EOT
  type = list(object({
    name                    = string
    ref_patterns            = list(string)
    creation_bypass_app_ids = optional(list(number), [])
  }))
  default = []
}
