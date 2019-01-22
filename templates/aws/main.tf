## The aws provider requires an access key and secret key to an account
## that already has access to IAM resources.
## In order to obtain these values, you have to download the credentials files
## from the AWS IAM console (https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)
## Once you have those values, set them as environment variables in the shell
## > export AWS_ACCESS_KEY="XXXXXXXXXXXXXXXXXX"
## > export AWS_SECRET_KEY="XXXXXXXXXXXXXXXXXX"
## Once vortex support cloud providers secret engines,
## this may change to make it easier in CI
{{ $ctx := . }}
provider "aws" {
  access_key = "{{ getenv "AWS_ACCESS_KEY" }}"
  secret_key = "{{ getenv "AWS_SECRET_KEY" }}"
  region     = "{{ $ctx.region }}"

  version = "1.56.0"
}


## Since AWS allows you to define the policies applied against resources,
## it is possible to generate each them relatively easily.
## It sets up all the required resources as it would be in the AWS console.
## I would strongly advocate that you use federated IAM access to make
## password management easy instead of having to set each password manually after the fact
{{ range $team := .teams }}
resource "aws_iam_group" "{{ $team.name }}" {
  name = "{{ $team.name }}"
  path = "{{ $team.path }}"
}

resource "aws_iam_group_membership" "{{ $team.name }}_membership" {
  name = "{{ $team.name }}"

  users = [{{ range $member := $team.members }}
    "${aws_iam_user.{{ $team.name }}_{{ md5 $member }}.name}",{{ end }}
  ]

  group = "${aws_iam_group.{{ $team.name }}.name}"
}

resource "aws_iam_group_policy" "{{$team.name}}_policy" {
  name = "{{ $team.name }}"
  group = "${aws_iam_group.{{ $team.name }}.id}"

  policy = << EOF
{{ $team.policy }}
EOF
}
  {{ range $member := $team.members }}
resource "aws_iam_user" "{{ $team.name }}_{{ md5 $member }}" {
  name = "{{ $member }}"
  path = "{{ $team.path }}"
}
  {{ end }}
{{ end }}
