/* Organization Policy: Denied Services  */

locals {
  disallowed_services = [
    //"bedrock",
    "nova",
  ]
}

// Data ========================================================================
data "aws_iam_policy_document" "denied_services" {
  statement { // Block the use of the service
    sid       = "DenyDisallowedServices"
    effect    = "Deny"
    actions   = [for service in local.disallowed_services : "${service}:*"]
    resources = ["*"]
  }
}

// Resources ===================================================================
resource "aws_organizations_policy" "denied_services" {
  name        = "DeniedServices"
  description = "Disallow the use of specified services."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.denied_services.json
  tags        = { Name = "${local.namespace}-org-policy-deniedservices" }
}

resource "aws_organizations_policy_attachment" "denied_services" {
  policy_id = aws_organizations_policy.denied_services.id
  target_id = aws_organizations_organization.this.roots[0].id
}
