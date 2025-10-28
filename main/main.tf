
locals {
  users = jsondecode(var.pim_users)

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
            module.rg.rg_id
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

