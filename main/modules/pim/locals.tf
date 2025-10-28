locals {
  pim_assignments = flatten([
    for key_pim, pim in var.pim_assignments : [
      for key_role, role in pim.roles : [
        for key_scope, scope in role.scopes :
        {
          key                 = "${replace(key_pim, " ", "-")}-${replace(key_role, " ", "-")}-${replace(key_scope, " ", "-")}"
          key_role_definition = "${replace(key_role, " ", "-")}-${replace(key_scope, " ", "-")}"
          object_id           = try(pim.object_id, null)
          display_name        = pim.type == "Group" ? pim.display_name : null
          user_principal_name = pim.type == "User" ? pim.user_principal_name : null
          mail_nickname       = pim.type == "User" ? pim.mail_nickname : null
          type                = pim.type
          assignment_type     = pim.assignment_type
          role_name           = key_role
          key_pim             = key_pim
          schedule            = pim.schedule
          condition           = pim.condition
          condition_version   = try(pim.condition, null) != null ? 2.0 : null
          scope               = scope
          justification       = pim.justification
        }
      ]
    ]
  ])

  approvers = flatten([
    for key_policy, policy in var.management_policies : [
      for key_approver, approver in try(policy.activation_rules.approval_stage.primary_approver, {}) : [
        {
          key                 = "${key_policy}-${key_approver}"
          object_id           = approver.object_id
          user_principal_name = approver.user_principal_name
          mail_nickname       = approver.mail_nickname
          display_name        = approver.display_name
          type                = approver.type
        }
      ]
    ]
  ])

  management_policies = flatten([
    for key_policy, policy in var.management_policies : [
      for key_role, role in policy.roles : [
        for key_scope, scope in role.scopes :
        {
          key_policy                = key_policy
          key                       = "${replace(key_policy, " ", "-")}-${replace(key_role, " ", "-")}-${replace(key_scope, " ", "-")}"
          key_role_definition       = "${replace(key_role, " ", "-")}-${replace(key_scope, " ", "-")}"
          role_name                 = key_role
          role                      = role
          scope                     = scope
          active_assignment_rules   = policy.active_assignment_rules
          eligible_assignment_rules = policy.eligible_assignment_rules
          activation_rules          = policy.activation_rules
          notification_rules        = policy.notification_rules
        }
  ]]])

  # Create a map of unique role definitions from both pim_assignments and management_policies
  pim_role_definitions = {
    for assignment in local.pim_assignments : assignment.key_role_definition => {
      key       = assignment.key_role_definition
      role_name = assignment.role_name
      scope     = assignment.scope
    }...
  }

  policy_role_definitions = {
    for policy in local.management_policies : policy.key_role_definition => {
      key       = policy.key_role_definition
      role_name = policy.role_name
      scope     = policy.scope
    }...
  }

  # Merge and flatten the grouped definitions, taking the first occurrence of each key
  all_role_definitions = merge(
    {
      for k, v in local.pim_role_definitions : k => v[0]
    },
    {
      for k, v in local.policy_role_definitions : k => v[0]
    }
  )
}   