###############################################################################
# ECR Tests
#

# Variables ===================================================================
variables {
  root_domain = "test.com"
}

# Tests =======================================================================
run "aws_ecr_repository" {
  assert {
    condition     = alltrue([for repo in aws_ecr_repository.ecr : repo.image_tag_mutability == "IMMUTABLE"])
    error_message = "Repo immutability mismatch."
  }
}
