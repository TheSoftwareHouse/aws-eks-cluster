output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "eks_managed_node_group_labels" {
  value       = { for k, v in module.eks.eks_managed_node_groups : k => v.node_group_labels }
  description = "EKS node group labels"
}

output "eks_managed_node_group_ids" {
  value       = [for k in module.eks.eks_managed_node_groups : k.node_group_id]
  description = "EKS node group ids"
}

output "karpenter_irsa_arn" {
  value       = module.karpenter[0].irsa_arn
  description = "Karpenter IRSA role ARN"
}

output "karpenter_queue_name" {
  value       = module.karpenter[0].queue_name
  description = "Karpenter SNS Queue name"
}

output "irsa_arns" {
  value       = { for k, v in module.iam_role_for_service_account : k => v.iam_role_arn }
  description = "IRSA roles ARNs"
}
