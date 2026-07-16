terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26.0"
    }
  }
}

# Configure the provider to talk to your Docker Desktop K8s API via Bastion
provider "kubernetes" {
  config_path = var.kube_config_path
}

# 1. Provision isolated tenant namespaces (staging & production)
resource "kubernetes_namespace" "platform_env" {
  for_each = toset(var.environments)

  metadata {
    name = each.key
    labels = {
      managed-by  = "terraform"
      environment = each.key
    }
  }
}

# 2. Enforce strict Resource Quotas to prevent any pod from exhausting cluster resources
resource "kubernetes_resource_quota" "env_quota" {
  for_each = toset(var.environments)

  metadata {
    name      = "${each.key}-compute-quota"
    namespace = kubernetes_namespace.platform_env[each.key].metadata[0].name
  }

  spec {
    hard = {
      "limits.cpu"    = var.cpu_quota_limit
      "limits.memory" = var.memory_quota_limit
      "pods"          = "10"
    }
  }
}

# 3. Create a dedicated CI/CD ServiceAccount inside each namespace
resource "kubernetes_service_account" "cicd_deployer" {
  for_each = toset(var.environments)

  metadata {
    name      = "jenkins-deployer-sa"
    namespace = kubernetes_namespace.platform_env[each.key].metadata[0].name
  }
}