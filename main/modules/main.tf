# existing
data "azurerm_client_config" "current" {}

data "azuread_group" "main" {
  for_each = {
    for gr in local.pim_assignments :
    gr.key => gr if gr.type == "Group" && gr.object_id == null
  }

  display_name               = each.value.display_name
  include_transitive_members = try(each.value.include_transitive_members, false)
  mail_enabled               = try(each.value.mail_enabled, null)
  mail_nickname              = try(each.value.mail_nickname, null)
  security_enabled           = try(each.value.security_enabled, null)
  object_id                  = try(each.value.object_id, null)
}

data "azuread_user" "main" {
  for_each = {
    for user in local.pim_assignments :
    user.key => user if user.type == "User" && user.object_id == null
  }

  user_principal_name = each.value.user_principal_name
  object_id           = each.value.object_id
  mail_nickname       = each.value.mail_nickname
  mail                = try(each.value.mail, null)
  employee_id         = try(each.value.employee_id, null)
}

data "azuread_user" "approver" {
  for_each = {
    for user in local.approvers :
    user.key => user if user.type == "User" && user.object_id == null
  }

  user_principal_name = each.value.user_principal_name
  object_id           = each.value.object_id
  mail_nickname       = each.value.mail_nickname
  mail                = try(each.value.mail, null)
  employee_id         = try(each.value.employee_id, null)
}

data "azuread_group" "approver" {
  for_each = {
    for group in local.approvers :
    group.key => group if group.type == "Group" && group.object_id == null
  }

  display_name               = each.value.display_name
  include_transitive_members = try(each.value.include_transitive_members, false)
  mail_enabled               = try(each.value.mail_enabled, null)
  mail_nickname              = try(each.value.mail_nickname, null)
  security_enabled           = try(each.value.security_enabled, null)
  object_id                  = try(each.value.object_id, null)
}


data "azurerm_role_definition" "default" {
  for_each = local.all_role_definitions

  name  = each.value.role_name
  scope = each.value.scope
}


resource "time_static" "start_date_time" {}

resource "azurerm_pim_active_role_assignment" "main" {
  for_each = {
    for pim in local.pim_assignments :
    pim.key => pim if pim.assignment_type == "Active"
  }

  principal_id = (each.value.object_id != null ? each.value.object_id : each.value.type == "User" ?
  data.azuread_user.main[each.value.key].object_id : data.azuread_group.main[each.value.key].object_id)
  scope              = each.value.scope != null ? each.value.scope : data.azurerm_client_config.current.subscription_id
  role_definition_id = data.azurerm_role_definition.default[each.value.key_role_definition].role_definition_id
  justification      = each.value.justification

  dynamic "schedule" {
    for_each = try(each.value.schedule, null) != null ? [each.value.schedule] : []

    content {
      start_date_time = try(schedule.value.start_date_time, time_static.start_date_time.rfc3339)

      dynamic "expiration" {
        for_each = schedule.value.expiration != null ? [schedule.value.expiration] : []

        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  dynamic "ticket" {
    for_each = try(each.value.ticket, null) != null ? [each.value.ticket] : []

    content {
      number = ticket.value.number
      system = ticket.value.system
    }
  }
}

resource "azurerm_pim_eligible_role_assignment" "main" {
  for_each = {
    for pim in local.pim_assignments :
    pim.key => pim if pim.assignment_type == "Eligible"
  }

  principal_id = (each.value.object_id != null ? each.value.object_id : each.value.type == "User" ?
  data.azuread_user.main[each.value.key].object_id : data.azuread_group.main[each.value.key].object_id)
  scope              = each.value.scope != null ? each.value.scope : data.azurerm_client_config.current.subscription_id
  role_definition_id = data.azurerm_role_definition.default[each.value.key_role_definition].role_definition_id
  justification      = each.value.justification
  condition          = each.value.condition
  condition_version  = each.value.condition_version

  dynamic "schedule" {
    for_each = try(each.value.schedule, null) != null ? [each.value.schedule] : []

    content {
      start_date_time = try(schedule.value.start_date_time, time_static.start_date_time.rfc3339)

      dynamic "expiration" {
        for_each = try(schedule.value.expiration, null) != null ? [schedule.value.expiration] : []

        content {
          duration_days  = expiration.value.duration_days
          duration_hours = expiration.value.duration_hours
          end_date_time  = expiration.value.end_date_time
        }
      }
    }
  }

  dynamic "ticket" {
    for_each = try(each.value.ticket, null) != null ? [each.value.ticket] : []

    content {
      number = ticket.value.number
      system = ticket.value.system
    }
  }
}

resource "azurerm_role_management_policy" "main" {
  for_each = {
    for policy in local.management_policies : policy.key => policy
  }

  scope              = each.value.scope != null ? each.value.scope : data.azurerm_client_config.current.subscription_id
  role_definition_id = data.azurerm_role_definition.default[each.value.key_role_definition].role_definition_id

  dynamic "active_assignment_rules" {
    for_each = each.value.active_assignment_rules != null ? [each.value.active_assignment_rules] : []
    content {
      expiration_required                = try(active_assignment_rules.value.expiration_required, false)
      expire_after                       = try(active_assignment_rules.value.expire_after, null)
      require_justification              = try(active_assignment_rules.value.require_justification, false)
      require_ticket_info                = try(active_assignment_rules.value.require_ticket_info, false)
      require_multifactor_authentication = try(active_assignment_rules.value.require_multifactor_authentication, false)
    }
  }

  dynamic "eligible_assignment_rules" {
    for_each = each.value.eligible_assignment_rules != null ? [each.value.eligible_assignment_rules] : []

    content {
      expiration_required = try(eligible_assignment_rules.value.expiration_required, false)
      expire_after        = try(eligible_assignment_rules.value.expire_after, null)
    }
  }

  dynamic "activation_rules" {
    for_each = each.value.activation_rules != null ? [each.value.activation_rules] : []

    content {
      require_justification                              = try(activation_rules.value.require_justification, false)
      require_ticket_info                                = try(activation_rules.value.require_ticket_info, false)
      require_multifactor_authentication                 = try(activation_rules.value.require_multifactor_authentication, false)
      required_conditional_access_authentication_context = try(activation_rules.value.required_conditional_access_authentication_context, false)
      require_approval                                   = try(activation_rules.value.require_approval, false)
      maximum_duration                                   = try(activation_rules.value.maximum_duration, null)

      dynamic "approval_stage" {
        for_each = activation_rules.value.approval_stage != null ? [activation_rules.value.approval_stage] : []

        content {
          dynamic "primary_approver" {
            for_each = approval_stage.value.primary_approver

            content {
              object_id = (
                primary_approver.value.object_id != null ?
                primary_approver.value.object_id : primary_approver.value.type == "User" ?
                data.azuread_user.approver["${each.value.key_policy}-${primary_approver.key}"].object_id :
                data.azuread_group.approver["${each.value.key_policy}-${primary_approver.key}"].object_id
              )
              type = primary_approver.value.type
            }
          }
        }
      }
    }
  }

  dynamic "notification_rules" {
    for_each = each.value.notification_rules != null ? [each.value.notification_rules] : []

    content {
      dynamic "active_assignments" {
        for_each = notification_rules.value.active_assignments != null ? [notification_rules.value.active_assignments] : []

        content {
          dynamic "admin_notifications" {
            for_each = active_assignments.value.admin_notifications != null ? [active_assignments.value.admin_notifications] : []

            content {
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
              notification_level    = admin_notifications.value.notification_level
              default_recipients    = admin_notifications.value.default_recipients
            }
          }
          dynamic "approver_notifications" {
            for_each = active_assignments.value.approver_notifications != null ? [active_assignments.value.approver_notifications] : []

            content {
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
              notification_level    = approver_notifications.value.notification_level
              default_recipients    = approver_notifications.value.default_recipients
            }
          }
          dynamic "assignee_notifications" {
            for_each = active_assignments.value.assignee_notifications != null ? [active_assignments.value.assignee_notifications] : []

            content {
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
              notification_level    = assignee_notifications.value.notification_level
              default_recipients    = assignee_notifications.value.default_recipients
            }
          }
        }
      }

      dynamic "eligible_assignments" {
        for_each = notification_rules.value.eligible_assignments != null ? [notification_rules.value.eligible_assignments] : []

        content {
          dynamic "admin_notifications" {
            for_each = eligible_assignments.value.admin_notifications != null ? [eligible_assignments.value.admin_notifications] : []

            content {
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
              notification_level    = admin_notifications.value.notification_level
              default_recipients    = admin_notifications.value.default_recipients
            }
          }
          dynamic "approver_notifications" {
            for_each = eligible_assignments.value.approver_notifications != null ? [eligible_assignments.value.approver_notifications] : []

            content {
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
              notification_level    = approver_notifications.value.notification_level
              default_recipients    = approver_notifications.value.default_recipients
            }
          }
          dynamic "assignee_notifications" {
            for_each = eligible_assignments.value.assignee_notifications != null ? [eligible_assignments.value.assignee_notifications] : []

            content {
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
              notification_level    = assignee_notifications.value.notification_level
              default_recipients    = assignee_notifications.value.default_recipients
            }
          }
        }
      }

      dynamic "eligible_activations" {
        for_each = notification_rules.value.eligible_activations != null ? [notification_rules.value.eligible_activations] : []

        content {
          dynamic "admin_notifications" {
            for_each = eligible_activations.value.admin_notifications != null ? [eligible_activations.value.admin_notifications] : []

            content {
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
              notification_level    = admin_notifications.value.notification_level
              default_recipients    = admin_notifications.value.default_recipients
            }
          }
          dynamic "approver_notifications" {
            for_each = eligible_activations.value.approver_notifications != null ? [eligible_activations.value.approver_notifications] : []

            content {
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
              notification_level    = approver_notifications.value.notification_level
              default_recipients    = approver_notifications.value.default_recipients
            }
          }
          dynamic "assignee_notifications" {
            for_each = eligible_activations.value.assignee_notifications != null ? [eligible_activations.value.assignee_notifications] : []

            content {
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
              notification_level    = assignee_notifications.value.notification_level
              default_recipients    = assignee_notifications.value.default_recipients
            }
          }
        }
      }
    }
  }
}
