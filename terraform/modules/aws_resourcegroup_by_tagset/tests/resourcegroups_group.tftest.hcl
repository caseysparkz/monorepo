###############################################################################
# ECR Tests
#

test { parallel = true }

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "us-west-2" }
  }
}

# Variables ===================================================================
variables {
  resource_group_name        = "test-resource-group"
  resource_group_description = "Test resource group."
  common_tags = {
    tag1 = "one"
    tag2 = "two"
    tag3 = "three"
  }
}

# Tests =======================================================================
run "aws_resourcegroups_group" {
  command = apply

  assert {
    condition     = can(regex("^.*:group/${var.resource_group_name}$", aws_resourcegroups_group.this.arn))
    error_message = "Invalid Resource Group name."
  }

  assert {
    condition = aws_resourcegroups_group.this.resource_query[0].query == jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        for key, value in var.common_tags : {
          Key    = key
          Values = [value]
        }
      ]
    })
    error_message = "Invalid tags."
  }

  assert {
    condition     = aws_resourcegroups_group.this.tags_all["Name"] == var.resource_group_name
    error_message = "Invalid tags."
  }

  assert {
    condition     = aws_resourcegroups_group.this.name == var.resource_group_name
    error_message = "Invalid name."
  }

  assert {
    condition     = aws_resourcegroups_group.this.id == var.resource_group_name
    error_message = "Invalid name."
  }

  assert {
    condition     = aws_resourcegroups_group.this.description == var.resource_group_description
    error_message = "Invalid description."
  }

  assert {
    condition     = aws_resourcegroups_group.this.region == "us-west-2"
    error_message = "Invalid region."
  }

  assert {
    condition     = aws_resourcegroups_group.this.resource_query[0].type == "TAG_FILTERS_1_0"
    error_message = "Invalid filter type."
  }
}
