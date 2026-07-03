# Usage

## Connecting a repository

Repositories are linked to a project through the REST API (see
[api.md](api.md)) — this is the primary interface. On create the plugin validates
the URL, clones a bare mirror under `mirror_root`, and registers a
`RemoteGit` repository on the project.

Once linked, the repository appears in the project's **Repository** tab and
behaves like any other git repository in Redmine: file browsing, revisions,
diffs, annotate, and issue linking from commit messages (`refs #123`).

### Authentication types

| `auth_type`   | How it authenticates                                             |
|---------------|------------------------------------------------------------------|
| `none`        | SSH using the Redmine server user's key (see deployment).        |
| `https_token` | HTTPS using a token supplied per repository (stored encrypted).  |

### Allowed URLs

Only these forms are accepted; everything else is rejected:

- `https://host/group/repo.git`
- `ssh://git@host[:port]/group/repo.git`
- scp-form `git@host:group/repo.git` (normalized to `ssh://`)

URLs containing shell metacharacters, `..`, or embedded credentials
(`https://user:token@host/...`) are refused.

## The Git overview page

The plugin adds a **Git** entry with a git icon to the top menu. It opens a
consolidated, cross-project overview of every RemoteGit repository the current
user is allowed to browse:

- a table of repositories (repository, project, project status, revision count,
  last change) — with a text **filter**, **click-to-sort** columns, and a
  separate collapsible section for repositories in **archived** projects;
- a **recent changes** list of the latest commits across all of those
  repositories.

The overview only lists repositories from projects where the user has the
`browse_repository` permission.

### Who sees the menu

In **Administration → Plugins → Redmine Remote Git** you can restrict the top-menu
Git entry:

- **Everyone logged in** (default);
- **Administrators only**;
- **Selected groups / users** — pick any groups and/or individual users.
  Administrators always see the entry.

The overview page enforces the same rule, so a direct link is not a bypass.

## Keeping repositories current

New commits appear after `Repository.fetch_changesets` runs (a cron job, see
deployment), when a repository page is viewed if `autofetch_changesets` is
enabled, or immediately via the API `fetch` action.

## Migrating from the old `redmine_git_remote` plugin

Stale rows left by the old plugin can be recovered with rake tasks:

```bash
# list stale Repository::GitRemote rows and the source URL recovered from each
sudo -u www-data RAILS_ENV=production bin/rails redmine_remote_git:list_orphans

# adopt one orphan by repository id: re-create it as RemoteGit and clone (in a transaction)
sudo -u www-data RAILS_ENV=production bin/rails redmine_remote_git:adopt[REPO_ID]
```

For repositories the old plugin stored as `Repository::Git` pointing at a local
mirror path, the real remote URL is taken from the mirror's `remote.origin.url`.
