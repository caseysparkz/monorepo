/* Cloudflare */

locals {
  cf_zone = data.terraform_remote_state.this.outputs.root_domain
}

// Data ========================================================================
data "cloudflare_zone" "this" {
  filter = { name = local.cf_zone }
}

// Resources ===================================================================
resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.id
  name    = "ecr"
  type    = "CNAME"
  content = module.ecr.ecr_registry_url
  ttl     = 1
  proxied = true
  comment = "Terraform managed."
}

resource "cloudflare_ruleset" "this" {
  name    = "redirect-ecr"
  kind    = "zone"
  zone_id = data.cloudflare_zone.this.id
  phase   = "http_request_dynamic_redirect"
  rules = [{
    action      = "redirect"
    description = "Redirect to ECR."
    enabled     = true
    expression  = "(http.request.full_uri wildcard r\"https://ecr.${local.cf_zone}/*\")"
    action_parameters = {
      from_value = {
        target_url = {
          expression = "wildcard_replace(http.request.full_uri, r\"https://ecr.${local.cf_zone}/*\", r\"https://${module.ecr.ecr_registry_url}/$${1}\")"
        }
        status_code           = 307
        preserve_query_string = true
      }
    }
  }]
}
