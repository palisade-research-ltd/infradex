# --------------------------------------------------------------------- IAM for EC2 --- #
# --------------------------------------------------------------------- ----------- --- #

# --- IAM ROLE --- #

resource "aws_iam_role" "ec2_s3_access" {
  name = "${var.pro_id}-ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# --- IAM POLICY --- #

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.pro_id}-ec2-s3-policy"
  role = aws_iam_role.ec2_s3_access.id

   policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:ListAllMyBuckets",
            "s3:GetBucketLocation",
            "ec2:DescribeInstances",
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetObjectVersion"
          ]
          Resource = [
            "arn:aws:s3:::*",
            "arn:aws:s3:::*/*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "iam:ListUsers",
          ]
          Resource = [
            "arn:aws:iam:::*"
          ]
        }
      ]
    })

}

# --- INSTANCE PROFILE EC2 --- #

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "${var.pro_id}-ec2-profile"
  role = aws_iam_role.ec2_s3_access.name

}

