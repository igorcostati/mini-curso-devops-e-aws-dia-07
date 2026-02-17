resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "labs-dvn-mini-curso-devops-e-aws-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}