module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.25.0"
  attributes = var.attributes
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

data "aws_lb" "alb_arn" {
  name = module.label.id
}

module "wafv2" {
  source        = "trussworks/wafv2/aws"
  version       = "2.4.0"

  name          = "${module.label.id}-web-acl"
  scope         = var.scope
  associate_alb = var.associate_alb
  #alb_arn       = module.label.id
  alb_arn       = data.aws_lb.alb_arn.arn

  managed_rules = var.managed_rules
  group_rules   = var.group_rules

  ip_rate_based_rule = var.ip_rate_based_rule

  ip_sets_rule = local.ip_sets_rule
}

output "web_acl_id" {
   value = module.wafv2.web_acl_id
}

locals {
    name_underbar = replace(var.name, "-", "_")

    ip_sets_rule = var.ip_set != null ? [ {
      name       = "${var.ip_set_action}_ips"
      action     = var.ip_set_action
      priority   = 1
      ip_set_arn = var.ip_set.arn
    }
  ] : []
}

resource "aws_ssm_parameter" "waf_web_acl_id" {
  name        = "/${var.namespace}/${var.stage}/waf/${local.name_underbar}"
  description = "the waf_acl_id for ${var.name}"
  type        = "String"
  value       = module.wafv2.web_acl_id
  overwrite   = true

  tags = {
    environment = var.stage
    notes       = "managed by terraform"
  }
}

