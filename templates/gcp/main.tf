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
  {{ range $user := $team.members }}
  {{ range $role := $team.roles }}
resource "google_project_iam_member" "{{$team.name}}_{{md5 $user $role}}" {
  project = "{{$ctx.project}}"

  role    = "{{$role}}"
  member  = "user:{{$email}}"
}
  {{ end }}
  {{ end }}
{{ end }}

## This will create all and manage all the services accounts
## defined inside the variables file.
## This is created in the same way as the member block to ensure
## that we do not override already existing accounts or accounts not managed
## by terraform.
## This will also output the service_account keys in base64 encoded so that
## they can be uploaded or stored in a more convenient manor
{{ range $serviceAccount := .serviceAccounts }}
resource "google_service_account" "{{$serviceAccount.name}}" {
  project      = "{{$ctx.project}}"
  account_id   = "{{$serviceAccount.name}}"
  display_name = "{{$serviceAccount.name}}"
}

resource "google_service_account_key" "{{$serviceAccount.name}}_key" {
  project            = "{{$ctx.project}}"
  service_account_id = "${google_service_account.{{$serviceAccount.name}}.name}"
}

output "{{$serviceAccount.name}}_private_key_base64_encoded" {
  value = "${google_service_account_key.{{$serviceAccount.name}}.private_key}"
}
  {{ range $role := $serviceAccount.roles}}
resource "google_service_account_iam_member" "{{$serviceAccount.name}}_{{md5 $role}}" {
  depends_on = ["google_service_account.{{$serviceAccount.name}}"]
  project    = "{{$ctx.project}}"

  role               = "{{$role}}"
  member             = "${google_service_account.{{$serviceAccount.name}}.email}"
  service_account_id = "${google_service_account.{{$serviceAccount.name}}.name}"
}
  {{ end }}
{{ end }}
