module "karpenter" {
  count   = var.enable_karpenter ? 1 : 0
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.0.0"

  cluster_name            = module.eks.cluster_name
  # irsa_oidc_provider_arn  = module.eks.oidc_provider_arn
  # enable_irsa             = true
  create_node_iam_role    = true
  create_instance_profile = true
  create_access_entry     = true
  namespace               = "karpenter"
  service_account         = "karpenter"

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  create_pod_identity_association = true

  tags = var.tags
}

resource "kubernetes_manifest" "karpenter_nodeclass" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiSelectorTerms = [{
        alias = "al2023@latest"
      }]

      role = module.karpenter[0].node_iam_role_name

      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]

      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = module.eks.cluster_name
        }
      }]

      tags = {
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
    }
  }
}

resource "kubernetes_manifest" "karpenter_nodepool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = kubernetes_manifest.karpenter_nodeclass.manifest.metadata.name
          }
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c", "m", "r"]
            },
            {
              key      = "karpenter.k8s.aws/instance-cpu"
              operator = "In"
              values   = ["4", "8", "16", "32"]
            },
            {
              key      = "karpenter.k8s.aws/instance-hypervisor"
              operator = "In"
              values   = ["nitro"]
            },
            {
              key      = "karpenter.k8s.aws/instance-generation"
              operator = "Gt"
              values   = ["2"]
            }
          ]
        }
      }
      limits = {
        cpu = "1000"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
      }
    }
  }
}
