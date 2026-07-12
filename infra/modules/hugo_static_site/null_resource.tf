################################################################################
# Terraform Data, Null Resources, and Local Executions
#
# Notes:  There's a LOT of REAL janky shit and filesystem checks in this module
#         that allow me to locally:
#             * Install node modules when ${var.hugo_dir}/package.json changes.
#             * Build the site when any build pages change.
#             * Deploy the site if any file in ${var.hugo_dir}/public/ changes.
#
#         These are emphatically **not** best pracices.
#         Always remember to ask an adult for help when using scissors.

locals {
  build_hash = sha256(join( # Hash used to detect if any website pages change.
    "",
    [
      for file in setsubtract(fileset(var.hugo_dir, "*"), fileset("${var.hugo_dir}/public", "*")) :
      filesha1("${var.hugo_dir}/${file}")
    ]
  ))
  node_modules_hash = sha256(join( # Hash used to detect if Node dependencies change.
    "",
    [
      for file in setunion(fileset(var.hugo_dir, "node_modules/*"), fileset(var.hugo_dir, "package.json")) :
      filesha1("${var.hugo_dir}/${file}")
    ]
  ))
}

# Resources ====================================================================
resource "local_file" "contact_form_js" {
  filename        = replace(var.js_contact_form_template_path, ".tftpl", "")
  file_permission = "0770"
  content = templatefile(
    var.js_contact_form_template_path,
    { lambda_url = aws_lambda_function_url.contact_form.function_url }
  )
}

resource "null_resource" "pnpm_selfupdate" {
  triggers = { build_hash = local.node_modules_hash }

  provisioner "local-exec" {
    command     = "pnpm self-update"
    working_dir = var.hugo_dir
  }
}

resource "null_resource" "pnpm_install" {
  depends_on = [null_resource.pnpm_selfupdate]
  triggers   = { build_hash = local.node_modules_hash }

  provisioner "local-exec" {
    command     = "pnpm install"
    working_dir = var.hugo_dir
  }
}

resource "null_resource" "compile_pages" {
  depends_on = [
    local_file.contact_form_js,
    null_resource.pnpm_install,
  ]
  triggers = {
    build_hash = local.build_hash
    contact_js = local_file.contact_form_js.content_sha1
  }

  provisioner "local-exec" {
    command     = "pnpm run build"
    working_dir = var.hugo_dir
  }
}

resource "null_resource" "deploy_site" {
  depends_on = [
    aws_s3_bucket.www_site,
    null_resource.compile_pages,
  ]
  triggers = null_resource.compile_pages.triggers

  provisioner "local-exec" {
    command = "aws s3 sync --delete ${var.hugo_dir}/public/ s3://${aws_s3_bucket.www_site.id}/"
  }
}
