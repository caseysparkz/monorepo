/* Permission Set: PowerUserAccess */

// Resources ===================================================================
resource "aws_ssoadmin_permission_set" "power_user_access" {
  name             = "PowerUserAccess"
  instance_arn     = local.aws_ssoadmin_instance_arn
  session_duration = "PT4H"
  tags             = { Name = "${local.namespace}-ssoadmin-permissionset-poweruseraccess" }
}

resource "aws_ssoadmin_managed_policy_attachment" "power_user_access" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.power_user_access.arn
}
