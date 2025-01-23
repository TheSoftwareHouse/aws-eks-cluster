module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.26.1"

  cluster_name = var.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  enable_irsa             = true
  create_instance_profile = true

  iam_role_name            = "${var.cluster_name}-KarpenterIRSA"
  iam_role_description     = "Karpenter IAM role for service account"
  iam_role_use_name_prefix = false
  iam_policy_name          = "KarpenterIRSA-${module.eks.cluster_name}"
  iam_policy_description   = "Karpenter IAM role for service account"
  create_iam_role          = false

  tags = merge(
    var.tags
  )
}
