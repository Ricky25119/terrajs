resource "azurerm_resource_group" "name" {
  name = "sample"
  location = "West Europe"
}

# Lookup Azure AD users for missing mail_nickname values (based on the input JSON name key)
data "azuread_user" "lookup" {
  for_each = {
    for u in jsondecode(var.pim_users) :
    u.name => u if u.type == "User" && (try(u.mail_nickname, "") == "") && (try(u.user_principal_name, "") != "")
  }

  user_principal_name = each.value.user_principal_name
}

locals {
  # decode input JSON and fill mail_nickname from Azure AD lookup when missing
  users = [
    for u in jsondecode(var.pim_users) : merge(
      u,
      {
        mail_nickname = coalesce(
          try(u.mail_nickname, null),
          try(lookup(data.azuread_user.lookup, u.name, null).mail_nickname, null)
        )
      }
    )
  ]

  pim_assignments = {
    for user in local.users : user.name => {
      type            = user.type
      mail_nickname   = user.mail_nickname
      justification   = "Automated PIM assignment"
      assignment_type = lookup(user, "assignment_type", "Eligible")
      schedule = {
        expiration = {
          duration_days  = lookup(user, "duration_days", null)
          duration_hours = lookup(user, "duration_hours", null)
        }
      }
      roles = {
        for role in user.roles : role.name => {
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
}
