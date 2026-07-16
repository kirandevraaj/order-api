output "provisioned_namespaces" {
  description = "The active Kubernetes namespaces managed by Terraform"
  value       = [for ns in kubernetes_namespace.platform_env : ns.metadata[0].name]
}

output "service_accounts" {
  description = "The CI/CD deployer service accounts created per namespace"
  value       = { for k, sa in kubernetes_service_account.cicd_deployer : k => sa.metadata[0].name }
}