################################################################################
# Main
#
# Author:       Casey Sparks
# Date:         June 29, 2026
# Description:  Easily create an AWS Resource Groups group.

# Resources ====================================================================
resource "aws_resourcegroups_group" "this" {
  name        = var.resource_group_name
  description = var.resource_group_description
  tags        = { Name = var.resource_group_name }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        for key, value in var.common_tags :
        {
          Key    = key
          Values = [value]
        }
      ]
    })
  }
}
