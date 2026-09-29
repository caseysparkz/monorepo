/* Permission Set: ReadOnlyAccess */

// Resources ===================================================================
resource "aws_ssoadmin_permission_set" "read_only_access" {
  name             = "ReadOnlyAccess"
  instance_arn     = local.aws_ssoadmin_instance_arn
  session_duration = "PT4H"
  tags             = { Name = "${local.namespace}-ssoadmin-permissionset-readonlyaccess" }
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only_access" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only_access.arn
}
