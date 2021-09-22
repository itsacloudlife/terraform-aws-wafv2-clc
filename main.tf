module "wafv2" {
  source        = "trussworks/wafv2/aws"
  version       = "2.4.0"
  name          = "dev-cloudfront-web-acl"
  scope         = "CLOUDFRONT"
  associate_alb = false #associated below
  managed_rules = [
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = [ "EC2MetaDataSSRF_BODY",
                          "NoUserAgent_HEADER",
                          "GenericRFI_BODY",
                          "GenericRFI_URIPATH",
                          "CrossSiteScripting_COOKIE",
                          "CrossSiteScripting_BODY",
                          "SizeRestrictions_BODY",
                          "SizeRestrictions_QUERYSTRING" ]
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


output "dev_cdn_wafv2" {
   value = module.dev_cdn_wafv2.web_acl_id
}

resource "aws_ssm_parameter" "waf_cl_id_dev" {
  provider    = aws.uswest2
  name        = "/waf_acl_id/dev"
  description = "the waf_acl_id for dev"
  type        = "String"
  value       = module.dev_cdn_wafv2.web_acl_id
  overwrite   = true

  tags = {
    environment = "dev"
    notes       = "managed by terraform"
  }
}

