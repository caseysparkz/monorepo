/* Shared locals and the resource group. */

mock_provider "aws" {
  override_during = plan
  source          = "./tests/mocks"
}

run "namespace_and_tags" {
  command = plan

  assert {
    condition     = local.namespace == "global-terraform-state"
    error_message = "Namespace changed; this renames nearly every resource in the manifest."
  }

  assert {
    condition     = local.common_tags.ManagedBy == "terraform" && local.common_tags.RepoPath == "infra/manifests/tfstate"
    error_message = "Common tags must identify how and where this manifest is managed."
  }
}

run "state_principals_are_deduplicated" {
  command = plan

  variables {
    writer_principal_arns = [
      "arn:aws:iam::111122223333:role/both",
      "arn:aws:iam::111122223333:role/writer",
    ]
    reader_principal_arns = [
      "arn:aws:iam::111122223333:role/both",
      "arn:aws:iam::111122223333:role/reader",
    ]
  }

  assert {
    condition = toset(local.state_principal_arns) == toset([
      "arn:aws:iam::111122223333:role/both",
      "arn:aws:iam::111122223333:role/reader",
      "arn:aws:iam::111122223333:role/writer",
    ]) && length(local.state_principal_arns) == 3
    error_message = "State principals must be the distinct union of readers and writers."
  }
}

run "resource_group_selects_on_common_tags" {
  command = plan

  assert {
    condition     = toset(jsondecode(one(aws_resourcegroups_group.this.resource_query).query).ResourceTypeFilters) == toset(["AWS::AllSupported"])
    error_message = "Resource group must include all supported resource types."
  }

  assert {
    condition = {
      for f in jsondecode(one(aws_resourcegroups_group.this.resource_query).query).TagFilters : f.Key => one(f.Values)
    } == local.common_tags
    error_message = "Resource group must filter on every common tag."
  }
}
