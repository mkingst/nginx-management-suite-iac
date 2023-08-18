/**
 * Copyright (c) F5, Inc.
 *
 * This source code is licensed under the Apache License, Version 2.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "aws_iam_role" "nms_ec2_assume_role" {
  name = "nms_ec2_assume_role"
  tags = {
    Owner = data.aws_caller_identity.current.user_ids
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "nms_ssm" {
  role       = aws_iam_role.nms_ec2_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  tags       = {
    Owner = data.aws_caller_identity.current.user_id
  }
}

resource "aws_iam_instance_profile" "nms_ssm" {
  name = "nms_ssm"
  role = aws_iam_role.nms_ec2_assume_role.name
  tags = {
    Owner = data.aws_caller_identity.current.user_id
  }
}

resource "aws_ssm_document" "restart_adm" {
  name          = "restart-adm"
  document_type = "Command"
  tags          = {
    Owner = data.aws_caller_identity.current.user_id
  }

  content = <<DOC
  {
    "schemaVersion": "2.2",
    "description": "Restart Application Delivery Manager to work",
    "mainSteps": [
      {
         "action": "aws:runShellScript",
         "name": "restart_adm",
         "inputs": {
            "timeoutSeconds": "60",
            "runCommand": [
               "systemctl restart nms-adm"
            ]
         }
      }
    ]
  }
DOC
}


resource "aws_ssm_association" "restart_adm" {
  name = aws_ssm_document.restart_adm.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.nms_example.id]
  }
  tags = {
    Owner = data.aws_caller_identity.current.user_id
  }
}