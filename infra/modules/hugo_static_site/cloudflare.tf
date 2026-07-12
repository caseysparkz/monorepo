################################################################################
# Cloudflare
#

locals {
  cloudflare_zone_id = data.cloudflare_zones.domain.result[0].id
  cloudflare_comment = "Terraform managed."
  cloudflare_dmarc_policy = { # Parsed to string
    p     = "reject"
    sp    = "reject"
    adkim = "s"
    aspf  = "s"
    fo    = "1"
    pct   = "5"
    rua   = "mailto:dmarc_rua@${var.root_domain}"
    ruf   = "mailto:dmarc_ruf@${var.root_domain}"
  }
}

# Data =========================================================================
data "cloudflare_zones" "domain" { name = var.root_domain } # Root zone

# Resources ====================================================================
resource "cloudflare_dns_record" "root_cname" { # Redirect bucket
  zone_id = local.cloudflare_zone_id
  name    = var.root_domain
  content = aws_s3_bucket_website_configuration.web_root.website_endpoint
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = local.cloudflare_comment
}

resource "cloudflare_dns_record" "subdomain_cname" { # Site bucket
  zone_id = local.cloudflare_zone_id
  name    = var.subdomain
  content = aws_s3_bucket_website_configuration.www_site.website_endpoint
  type    = "CNAME"
  ttl     = 1
  proxied = true
  comment = local.cloudflare_comment
}

resource "cloudflare_dns_record" "ses_verification" { # Verify domain ownership
  zone_id = local.cloudflare_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.root_domain.id}"
  content = aws_ses_domain_identity.root_domain.verification_token
  type    = "TXT"
  ttl     = 1
  proxied = false
  comment = local.cloudflare_comment
}

resource "cloudflare_dns_record" "subdomain_mx" { # SES MX record
  zone_id  = local.cloudflare_zone_id
  name     = var.subdomain
  content  = "feedback-smtp.${data.aws_region.current.region}.amazonses.com"
  type     = "MX"
  ttl      = 1
  priority = 10
  proxied  = false
  comment  = local.cloudflare_comment
}

resource "cloudflare_dns_record" "subdomain_spf" { # SPF record
  zone_id = local.cloudflare_zone_id
  name    = var.subdomain
  content = "v=spf1 include:amazonses.com -all"
  type    = "TXT"
  ttl     = 1
  proxied = false
  comment = local.cloudflare_comment
}

resource "cloudflare_dns_record" "dkim" { # DKIM record
  count   = 3
  zone_id = local.cloudflare_zone_id
  name    = "${aws_ses_domain_dkim.root_domain.dkim_tokens[count.index]}._domainkey"
  content = "${aws_ses_domain_dkim.root_domain.dkim_tokens[count.index]}.dkim.amazonses.com"
  type    = "CNAME"
  ttl     = 1
  proxied = false
  comment = local.cloudflare_comment
}
