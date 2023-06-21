data "aws_caller_identity" "current" {}

locals {
  eks_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = var.create_aws_ebs_csi_driver_irsa_role ? "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${local.aws_ebs_csi_driver_irsa_role[0].name}IRSA-${var.cluster_name}" : null # id konta do data
    }
  }

  karpenter_irsa_name = "KarpenterIRSA-${var.cluster_name}"
  karpenter_aws_auth_role = var.enable_karpenter ? [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.karpenter_irsa_name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ] : []
  karpenter_node_security_group_tags = var.enable_karpenter ? { "karpenter.sh/discovery" = var.cluster_name } : {}
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  ## Addons
  cluster_addons = {
    coredns            = var.enable_coredns ? local.eks_addons.coredns : null
    kube-proxy         = var.enable_kube_proxy ? local.eks_addons.kube-proxy : null
    vpc-cni            = var.enable_vpc_cni ? local.eks_addons.vpc-cni : null
    aws-ebs-csi-driver = var.enable_aws_ebs_csi_driver ? local.eks_addons.aws-ebs-csi-driver : null
  }

  ## VPC & Network
  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    min_size       = 1
    max_size       = 1
    desired_size   = 1
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t3a.nano", "t3a.micro", "t3a.small", "t3a.medium", "t3a.large"]
  }

  eks_managed_node_groups = {
    production-ng = {
      name                     = "${var.cluster_name}-production-ng"
      use_name_prefix          = false
      min_size                 = lookup(var.eks_production_node_group, "min_size", 0)
      max_size                 = lookup(var.eks_production_node_group, "max_size", 1)
      desired_size             = lookup(var.eks_production_node_group, "desired_size", 0)
      capacity_type            = lookup(var.eks_production_node_group, "capacity_type", "ON_DEMAND")
      instance_types           = lookup(var.eks_production_node_group, "instance_types", ["t3.medium"])
      create_iam_role          = true
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.cluster_name}-EKSNodeGroupsRole"

      iam_role_additional_policies = {
        ElasticLoadBalancingReadOnly = "arn:aws:iam::aws:policy/ElasticLoadBalancingReadOnly"
      }

      labels = {
        "environment" = "production"
      }

      tags = merge(
        var.tags,
        lookup(var.eks_production_node_group, "tags", {})
      )
    }

    staging-ng = {
      name            = "${var.cluster_name}-staging-ng"
      use_name_prefix = false
      min_size        = lookup(var.eks_staging_node_group, "min_size", 3)
      max_size        = lookup(var.eks_staging_node_group, "max_size", 3)
      desired_size    = lookup(var.eks_staging_node_group, "desired_size", 3)
      capacity_type   = lookup(var.eks_staging_node_group, "capacity_type", "SPOT")
      instance_types  = lookup(var.eks_staging_node_group, "instance_types", ["t3.medium"])
      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.id}:role/${var.cluster_name}-EKSNodeGroupsRole"

      labels = {
        "environment" = "staging"
      }

      tags = merge(
        var.tags,
        lookup(var.eks_staging_node_group, "tags", {})
      )
    }
  }

  ## Security Group
  cluster_security_group_name = "${var.cluster_name}-cluster-sg"
  node_security_group_name    = "${var.cluster_name}-node-sg"

  ## KMS
  create_kms_key          = true
  enable_kms_key_rotation = true
  kms_key_owners          = var.kms_key_owners
  kms_key_administrators  = var.kms_key_administrators
  kms_key_service_users   = var.kms_key_service_users
  kms_key_users           = var.kms_key_users
  kms_key_description     = "KMS Key for Kubernetes Secrets Encryption"

  # aws-auth configmap
  manage_aws_auth_configmap = true
  aws_auth_roles            = flatten(concat(local.karpenter_aws_auth_role, var.aws_auth_roles))

  ## Tags
  cluster_security_group_tags = var.cluster_security_group_tags
  node_security_group_tags    = merge(var.node_security_group_tags, local.karpenter_node_security_group_tags)
  cluster_tags                = var.cluster_tags
  tags                        = var.tags
}

## IRSA roles
locals {
  aws_ebs_csi_driver_irsa_role = var.enable_aws_ebs_csi_driver && var.create_aws_ebs_csi_driver_irsa_role ? [{
    name                  = "ebs-csi-controller-sa"
    namespace             = "kube-system"
    attach_ebs_csi_policy = true
  }] : []

  aws_load_balancer_controller_irsa_role = var.enable_aws_load_balancer_controller && var.create_aws_load_balancer_controller_irsa_role ? [{
    name                                   = "aws-load-balancer-controller"
    namespace                              = "kube-system"
    attach_load_balancer_controller_policy = true
  }] : []

  external_dns_irsa_role = var.enable_external_dns && var.create_external_dns_irsa_role ? [{
    name                       = "external-dns"
    namespace                  = "kube-system"
    attach_external_dns_policy = true
  }] : []

  irsa_roles = { for i in flatten(concat(
    local.aws_ebs_csi_driver_irsa_role,
    local.aws_load_balancer_controller_irsa_role,
    local.external_dns_irsa_role,
    var.additional_irsa_roles
  )) : i.name => i }
}

module "iam_role_for_service_account" {
  for_each = local.irsa_roles
  source   = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version  = "5.20.0"

  role_name                              = "${each.value.name}IRSA-${var.cluster_name}"
  attach_load_balancer_controller_policy = lookup(each.value, "attach_load_balancer_controller_policy", false)
  attach_ebs_csi_policy                  = lookup(each.value, "attach_ebs_csi_policy", false)
  attach_external_dns_policy             = lookup(each.value, "attach_external_dns_policy", false)
  role_policy_arns                       = lookup(each.value, "role_policy_arns", {})

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${each.value.namespace}:${each.value.name}"]
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))

  depends_on = [
    module.eks
  ]
}
