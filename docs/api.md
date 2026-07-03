# REST API

The plugin exposes a REST API for managing the git repositories linked to a
project (Redmine core has no repository API — this fills that gap).

## Authentication and permissions

- Send your Redmine API key in the `X-Redmine-API-Key` header (REST API must be
  enabled in Administration → Settings → API).
- **Read** (`index`, `show`) requires the `browse_repository` permission on the
  project; **write** (`create`, `update`, `destroy`, `fetch`) requires
  `manage_repository`.

## Endpoints

All endpoints are nested under a project. `:project_id` may be the numeric id or
the project identifier.

| Method   | Path                                         | Action                                    |
|----------|----------------------------------------------|-------------------------------------------|
| `GET`    | `/projects/:project_id/git_repos.json`       | list linked repositories                  |
| `GET`    | `/projects/:project_id/git_repos/:id.json`   | show one repository                       |
| `POST`   | `/projects/:project_id/git_repos.json`       | link a repository (clones a mirror)       |
| `PUT`    | `/projects/:project_id/git_repos/:id.json`   | update auth / credential                  |
| `DELETE` | `/projects/:project_id/git_repos/:id.json`   | unlink a repository (removes its mirror)  |
| `POST`   | `/projects/:project_id/git_repos/:id/fetch.json` | fetch new commits and import changesets |

## Parameters

Write requests wrap parameters in `remote_git[...]`:

| Parameter          | Used by        | Description                                                   |
|--------------------|----------------|--------------------------------------------------------------|
| `url`              | create         | git URL (`https://`, `ssh://`, or scp-form)                  |
| `identifier`       | create         | repository identifier (optional; derived from the URL)       |
| `auth_type`        | create, update | `none` or `https_token`                                      |
| `credential`       | create, update | HTTPS token — **write-only**, never returned                 |
| `credential_login` | create, update | login for the token (defaults to `oauth2`)                   |
| `is_default`       | create         | make this the project's default repository                   |

## Response

The `git_repo` object never includes the credential. Fields:

```json
{
  "git_repo": {
    "id": 8,
    "identifier": "remote-git",
    "source_url": "ssh://git@git.example.com:5022/group/repo.git",
    "auth_type": "none",
    "has_credential": false,
    "vault_key_id": null,
    "is_default": true,
    "last_fetch_at": "2026-07-03T06:44:50Z",
    "last_error": null
  }
}
```

## Examples

Link an SSH repository (server-side key auth):

```bash
curl -H "X-Redmine-API-Key: $KEY" \
  --data-urlencode "remote_git[url]=ssh://git@git.example.com:5022/group/repo.git" \
  --data-urlencode "remote_git[is_default]=1" \
  https://redmine.example.com/projects/MYPROJECT/git_repos.json
```

Link an HTTPS repository with a token:

```bash
curl -H "X-Redmine-API-Key: $KEY" \
  --data-urlencode "remote_git[url]=https://github.com/org/repo.git" \
  --data-urlencode "remote_git[auth_type]=https_token" \
  --data-urlencode "remote_git[credential]=ghp_XXXX" \
  https://redmine.example.com/projects/MYPROJECT/git_repos.json
```

List linked repositories (the response contains no secrets):

```bash
curl -H "X-Redmine-API-Key: $KEY" \
  https://redmine.example.com/projects/MYPROJECT/git_repos.json
```

Fetch new commits for repository 8:

```bash
curl -X POST -H "X-Redmine-API-Key: $KEY" \
  https://redmine.example.com/projects/MYPROJECT/git_repos/8/fetch.json
```

Unlink a repository (also deletes its on-disk mirror):

```bash
curl -X DELETE -H "X-Redmine-API-Key: $KEY" \
  https://redmine.example.com/projects/MYPROJECT/git_repos/8.json
```

## Errors

- Invalid or unsafe URLs, git failures, and validation errors return
  `422 Unprocessable Entity` with `{"errors": [ ... ]}`.
- A request without the required permission returns `403 Forbidden`.
