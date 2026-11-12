output "resource_group_name" { value = module.braintrust.resource_group_name }
output "aks_cluster_name" { value = module.braintrust.aks_cluster_name }
output "key_vault_id" { value = module.braintrust.key_vault_id }
output "storage_account_id" { value = module.braintrust.storage_account_id }
output "workload_identity_client_id" { value = module.braintrust.workload_identity_client_id }
output "helm_object_storage_values" { value = module.braintrust.helm_object_storage_values }

output "ea_configuration" { value = module.braintrust.ea_configuration }

output "main_vnet_address_spaces" { value = module.braintrust.main_vnet_address_spaces }
