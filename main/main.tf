resource "azurerm_resource_group" "name" {
  name = "sample"
  location = "West Europe"
}

# Lookup Azure AD users for missing mail_nickname values (based on the input JSON name key)
locals {
  # decode input JSON and fill mail_nickname from Azure AD lookup when missing
  groups = jsondecode(var.pim_groups)

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
}
