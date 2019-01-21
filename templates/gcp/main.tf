## By default, the google provider will assume the account logged in
## within the environment
## The account being used needs to have the role "owner" applied to it
## within the project the script is trying to update.
## To configure the environment to use a service account in a CI/CD
## environment, You'll need to export the path to the service account key using:
## > export GOOGLE_CLOUD_KEYFILE_JSON="path/to/service/account.json"
{{ $ctx := . }}
provider "google" {
  project = "{{$ctx.project}}"
  region  = "{{$ctx.region}}"

  version = "1.20.0"
}

## In order to generate all the users and not create unreadable diffs
## with terraform plan. The template generate a resource for
## each indivual team + user + role
## This makes it easier to read plans and ensure that terraform isn't
## going to remove things it shouldn't
## This is particularlly important with service accounts
## as roles applied to them may overlap with roles used on members
{{ range $team := .teams }}
  {{ range $user, $email := $team.members }}
  {{ range $role   := $team.roles }}
resource "google_project_iam_member" "{{$team.name}}_{{$user}}_{{md5 $role}}" {
  project = "{{$ctx.project}}"
  role    = "{{$role}}"
  member  = "user:{{$email}}"
}
  {{ end }}
  {{ end }}
{{ end }}
