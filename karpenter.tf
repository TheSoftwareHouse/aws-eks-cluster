module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.33.1"

  cluster_name = var.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_irsa              = true
  irsa_name                = "${var.cluster_name}-KarpenterIRSA"
  irsa_use_name_prefix     = false
  create_instance_profile  = true
  create_iam_role          = false
  iam_role_use_name_prefix = false
  iam_role_arn             = module.eks.eks_managed_node_groups["spot"].iam_role_arn

  tags = merge(
    var.tags
  )
}
