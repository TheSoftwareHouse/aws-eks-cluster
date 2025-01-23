output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS Cluster Name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS Cluster Endpoint"
}

output "eks_managed_node_group_labels" {
  value       = { for k, v in module.eks.eks_managed_node_groups : k => v.node_group_labels }
  description = "EKS Node Group Labels"
}

output "eks_managed_node_group_ids" {
  value       = [for k in module.eks.eks_managed_node_groups : k.node_group_id]
  description = "EKS Node Group IDs"
}

output "karpenter_iam_role_arn" {
  value = module.karpenter[0].iam_role_arn
}

output "karpenter_queue_name" {
  value       = module.karpenter[0].queue_name
  description = "Karpenter SQS Queue Name"
}

output "irsa_arns" {
  value       = { for k, v in module.iam_role_for_service_account : k => v.iam_role_arn }
  description = "IRSA Roles ARNs"
}
