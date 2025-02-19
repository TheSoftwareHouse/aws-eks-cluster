variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}

## VPC
variable "vpc_id" {
  type = string
}

variable "vpc_subnets" {
  type = list(string)
}

variable "enable_aws_ebs_csi_driver" {
  type        = bool
  default     = false
  description = "AWS EBS CSI driver"
}

variable "enable_aws_load_balancer_controller" {
  type        = bool
  default     = false
  description = "AWS Load Balancer controller"
}

variable "enable_external_dns" {
  type        = bool
  default     = false
  description = "ExternalDNS addon"
}

variable "create_aws_ebs_csi_driver_irsa_role" {
  type        = bool
  default     = false
  description = "AWS EBS CSI driver IRSA role"
}

variable "create_aws_load_balancer_controller_irsa_role" {
  type        = bool
  default     = false
  description = "AWS Load Balancer controller IRSA role"
}

variable "create_external_dns_irsa_role" {
  type        = bool
  default     = false
  description = "ExternalDNS IRSA role"
}

variable "additional_irsa_roles" {
  type = list(object({
    name             = string
    namespace        = string
    role_policy_arns = optional(map(string))
  }))
  default = []
}

# Karpenter
variable "enable_karpenter" {
  type        = bool
  default     = false
  description = "Karpenter"
}

variable "kms_key_owners" {
  type        = list(string)
  default     = []
  description = "A list of IAM ARNs for those who will have full key permissions (`kms:*`)"
}

variable "kms_key_administrators" {
  type        = list(string)
  default     = []
  description = "A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available"
}

variable "kms_key_service_users" {
  type        = list(string)
  default     = []
  description = "A list of IAM ARNs for [key service users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration)"
}

variable "kms_key_users" {
  type        = list(string)
  default     = []
  description = "A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users)"
}

## Node Groups
variable "eks_production_node_group" {
  type        = map(any)
  default     = {}
  description = "Map of EKS managed production node group definitions to create"
}

variable "aws_auth_roles" {
  type        = list(any)
  default     = []
  description = ""
}

## Tags
variable "cluster_security_group_tags" {
  type    = map(string)
  default = {}
}

variable "node_security_group_tags" {
  type    = map(string)
  default = {}
}

variable "cluster_tags" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
