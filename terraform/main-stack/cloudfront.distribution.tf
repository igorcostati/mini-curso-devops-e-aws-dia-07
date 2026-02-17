resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = aws_s3_bucket.this.bucket_regional_domain_name
  }

  # origin {
  #   domain_name = data.aws_lb.this.dns_name
  #   origin_id   = data.aws_lb.this.dns_name 
  #
  #   custom_origin_config {
  #     http_port              = 80
  #     https_port             = 443
  #     origin_protocol_policy = "http-only"
  #     origin_ssl_protocols   = ["TLSv1.2"]
  #   }  
  # }

  enabled             = true
  default_root_object = "index.html"

  aliases = ["labs-devops-na-nuvem.tecnologia-i.com.br"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.this.bucket_regional_domain_name

    #Managed-CachingOptimized
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "allow-all"
  }

  # ordered_cache_behavior {
  #   path_pattern     = "/backend/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  #   cached_methods   = ["GET", "HEAD", "OPTIONS"]
  #   target_origin_id = data.aws_lb.this.dns_name 
  #   #UseOriginCacheControlHeaders-QueryStrings
  #   cache_policy_id = "4cc15a8a-d715-48a4-82b8-cc0b614638fe"
  #   #Managed-AllViewer
  #   origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  #   viewer_protocol_policy = "redirect-to-https"
  # }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.this.arn
    ssl_support_method  = "sni-only"
  }
}
 