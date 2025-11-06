resource "azurerm_resource_group" "name" {
  name = "sample"
  location = "West Europe"
}

# Lookup Azure AD users for missing mail_nickname values (based on the input JSON name key)
locals {
  # decode input JSON and fill mail_nickname from Azure AD lookup when missing
  groups = jsondecode(var.pim_groups)
  mgmt_policies = jsondecode(var.management_policies)

  management_policies = {
    for policy in local.management_policies : policy.name => {
      roles = {
        for role in policy.roles : role.name => {
          scopes = [
            azurerm_resource_group.name.id
          ]
        }
      }

      activation_rules = {
        require_justification              = lookup(policy.activation_rules, "require_justification", true)
        require_ticket_info                = lookup(policy.activation_rules, "require_ticket_info", true)
        require_multifactor_authentication = lookup(policy.activation_rules, "require_multifactor_authentication", false)
        require_approvals                  = lookup(policy.activation_rules, "require_approvals", false)
        maximum_duration                   = lookup(policy.activation_rules, "maximum_duration", "PT4H")
        approval_stage = {
          primary_approver = {
            type         = "Group"
            display_name = lookup(policy.activation_rules, "approval_group", "ApprovalGroup")
          }
        }
      }

      eligible_assignment_rules = {
        expiration_required = true
        expire_after        = lookup(policy.eligible_assignment_rules, "expire_after", "P365D")
      }

      active_assignment_rules = {
        expiration_required                = true
        expire_after                       = lookup(policy.active_assignment_rules, "expire_after", "P0D")
        require_justification              = lookup(policy.active_assignment_rules, "require_justification", true)
        require_ticket_info                = lookup(policy.active_assignment_rules, "require_ticket_info", true)
        require_multifactor_authentication = lookup(policy.active_assignment_rules, "require_multifactor_authentication", false)
      }

      notification_rules = lookup(policy, "notification_rules", {
        eligible_assignments = {
          admin_notifications = {
            default_recipients    = true
            notification_level    = "None"
            additional_recipients = []
          }
          approver_notifications = {
            default_recipients    = true
            notification_level    = "None"
            additional_recipients = []
          }
          assignee_notifications = {
            default_recipients    = true
            notification_level    = "None"
            additional_recipients = []
          }
        }
      })
    }
  }

 
  pim_assignments = {
    for group in local.groups : group.name => {
      type            = group.type
      display_name   = group.group_name
      justification   = "Automated PIM assignment"
      assignment_type = lookup(group, "assignment_type", "Eligible")
      schedule = {
        expiration = {
          duration_days  = lookup(group, "duration_days", null)
          duration_hours = lookup(group, "duration_hours", null)
        }
      }
      roles = {
        for role in group.roles : role.name => {
          scopes = [
            azurerm_resource_group.name.id
          ]
        }
      }
    }
  }
}

module "pim" {
  source = "./modules/pim"
  pim_assignments = local.pim_assignments
  management_policies = loc
}
