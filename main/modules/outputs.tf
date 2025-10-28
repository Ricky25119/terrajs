output "pim_active_role_assignments" {
  description = "contains all pim active role assignments"
  value       = azurerm_pim_active_role_assignment.main
}

output "pim_eligible_role_assignments" {
  description = "contains all pim eligible role assignments"
  value       = azurerm_pim_eligible_role_assignment.main
}

output "pim_role_management_policies" {
  description = "contains all pim role management policies"
  value       = azurerm_role_management_policy.main
}