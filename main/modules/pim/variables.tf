variable "pim_assignments" {
  description = "Map of 1 or more PIM assignment(s)"
  type = map(object({
    object_id           = optional(string)             # Use Object ID for User or Group instead of user_principal_name or display_name
    assignment_type     = optional(string, "Eligible") # "Eligible" or "Active"
    user_principal_name = optional(string)             # Required if type is "User" and object_id or mail_nickname is not provided
    mail_nickname       = optional(string)             # Required if type is "User" and object_id or user_principal_name is not provided
    display_name        = optional(string)             # Required if type is "Group" and object_id is not provided
    type                = string                       # "User" or "Group"
    roles = map(object({
      scopes = list(string) # List of scopes, can be subscriptions, resource groups, management groups
    }))
    justification     = optional(string, "No justification provided")
    condition         = optional(string, null)
    condition_version = optional(number, 2.0) # Only supported value is 2.0, required if condition is set
    schedule = optional(object({
      start_date_time = optional(string)
      expiration = optional(object({
        duration_days  = optional(number)
        duration_hours = optional(number)
        end_date_time  = optional(string)
      }))
    }), null)
    ticket = optional(object({
      number = optional(string)
      system = optional(string)
    }))
  }))
  default = {}
}

variable "management_policies" {
  description = "Map of 1 or more management policies"
  type = map(object({
    roles = map(object({
      scopes = list(string) # List of scopes, can be subscriptions, resource groups, management groups
    }))
    active_assignment_rules = optional(object({
      expiration_required                = optional(bool)
      expire_after                       = optional(string) ## P15D, P30D, P90D, P180D, P365D
      require_justification              = optional(bool)
      require_ticket_info                = optional(bool)
      require_multifactor_authentication = optional(bool)
    }))
    eligible_assignment_rules = optional(object({
      expiration_required = optional(bool)
      expire_after        = optional(string) ## P15D, P30D, P90D, P180D, P365D
    }))
    activation_rules = optional(object({
      require_justification                              = optional(bool)
      require_ticket_info                                = optional(bool)
      require_multifactor_authentication                 = optional(bool)
      required_conditional_access_authentication_context = optional(bool)
      require_approvals                                  = optional(bool)
      maximum_duration                                   = optional(string)
      approval_stage = optional(object({
        primary_approver = map(object({
          type                = string           # "User" or "Group"
          user_principal_name = optional(string) # In case type is "User"
          mail_nickname       = optional(string) # In case type is "User"
          display_name        = optional(string) # In case type is "Group"
          object_id           = optional(string) # Object ID can be used instead of upn or display_name
        }))
      }))
    }))
    notification_rules = optional(object({
      active_assignments = optional(object({
        admin_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        approver_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        assignee_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
      }))
      eligible_assignments = optional(object({
        admin_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        approver_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        assignee_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
      }))
      eligible_activations = optional(object({
        admin_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        approver_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
        assignee_notifications = optional(object({
          additional_recipients = optional(list(string))
          default_recipients    = optional(bool, true)
          notification_level    = string # "All" or "Critical"
        }))
      }))
    }))
  }))
  default = {}
}