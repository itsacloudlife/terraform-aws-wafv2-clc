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

  managed_rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList",
      priority        = 20
      override_action = "count"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet",
      priority        = 30
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesLinuxRuleSet",
      priority        = 40
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesPHPRuleSet",
      priority        = 50
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesWordPressRuleSet",
      priority        = 60
      override_action = "none"
      excluded_rules  = []
    }
  ]
}

output "web_acl_id" {
   value = module.wafv2.web_acl_id
}

locals {
    name_underbar = replace(var.name, "-", "_")
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

