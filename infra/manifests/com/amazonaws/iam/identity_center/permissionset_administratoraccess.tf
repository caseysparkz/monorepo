/* Permission Set: AdministratorAccess */

// Resources ===================================================================
resource "aws_ssoadmin_permission_set" "administrator_access" {
  name             = "AdministratorAccess"
  instance_arn     = local.aws_ssoadmin_instance_arn
  session_duration = "PT4H"
  tags             = { Name = "${local.namespace}-ssoadmin-permissionset-administratoraccess" }
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_access" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "aws_billing_conductor_full_access" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSBillingConductorFullAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "aws_cost_and_usage_report_automation_policy" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCostAndUsageReportAutomationPolicy"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "cost_optimization_hub_admin_access" {
  instance_arn       = local.aws_ssoadmin_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/CostOptimizationHubAdminAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
}
