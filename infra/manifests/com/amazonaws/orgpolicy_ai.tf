/* Organization Policy: AI Services Opt-out */

// Resources ===================================================================
/*
resource "aws_organizations_policy" "ai_opt_out" {
  name        = "AiOptOut"
  description = "AI opt-out policy."
  type        = "AISERVICES_OPT_OUT_POLICY"
  content = jsonencode({ "services" : { "default" : { "opt_out_policy" : {
    "@@assign" : "optOut",
    "@@operators_allowed_for_child_policies" : ["@@none"]
  } } } })
  tags = { Name = "${local.namespace}-org-policy-aioptout" }
}

resource "aws_organizations_policy_attachment" "ai_opt_out" {
  policy_id = aws_organizations_policy.ai_opt_out.id
  target_id = aws_organizations_organization.this.roots[0].id
}
*/
