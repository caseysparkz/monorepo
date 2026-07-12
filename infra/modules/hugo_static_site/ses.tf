################################################################################
# AWS SES
#

# Resources ====================================================================
resource "aws_ses_domain_identity" "root_domain" { domain = var.root_domain }

resource "aws_ses_domain_identity_verification" "root_domain" {
  depends_on = [cloudflare_dns_record.ses_verification]
  domain     = aws_ses_domain_identity.root_domain.id
}

resource "aws_ses_domain_dkim" "root_domain" {
  domain = aws_ses_domain_identity.root_domain.id
}

resource "aws_ses_email_identity" "default_sender" {
  email = local.email_headers["default_sender"]
}

resource "aws_ses_email_identity" "default_recipient" {
  email = local.email_headers["default_recipient"]
}

resource "aws_ses_domain_mail_from" "subdomain" {
  depends_on       = [aws_ses_domain_identity_verification.root_domain]
  domain           = var.root_domain
  mail_from_domain = var.subdomain
}
