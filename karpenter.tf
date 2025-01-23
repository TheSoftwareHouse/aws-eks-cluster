module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.33.1"

  cluster_name            = var.cluster_name
  enable_irsa             = true
  irsa_oidc_provider_arn  = module.eks.oidc_provider_arn
  create_instance_profile = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}
