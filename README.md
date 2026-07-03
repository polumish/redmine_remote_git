# redmine_remote_git

A Redmine plugin that links **external git repositories** (SSH or HTTPS, any host)
to projects through a REST API and browses them with Redmine's built-in git
support. It is a thin orchestration layer over core `Repository::Git` and replaces
the unmaintained `dergachev/redmine_git_remote`.

## What it does

- Link any external git repository to a project **via a REST API** (Redmine core
  has no repository API) — full file browsing, revisions, diffs, annotate, and
  issue linking work as for any git repository.
- A global **Git** top-menu entry opens a cross-project overview of all linked
  repositories with filtering, sorting, an archived-projects section, and a recent
  changes list. Menu visibility is configurable (everyone / admins / selected
  groups and users).
- SSH (server key) or HTTPS (per-repository token) authentication.
- Bare `--mirror` clones stored outside the plugin directory, under a configurable
  `mirror_root`; mirrors are removed when a repository is unlinked.
- Rake tasks to migrate away from the old `redmine_git_remote` plugin.

## Security

- HTTPS tokens are encrypted at rest (AES-256-GCM). A token is **write-only** over
  the API — it is never returned in a response and never written to a mirror's git
  config; it reaches git only through a temporary `GIT_ASKPASS` helper.
- Strict URL validation: only `https://`, `ssh://`, and scp-form URLs are allowed;
  shell metacharacters, `..` path segments, and URLs with embedded credentials are
  rejected. Git is always invoked with an argv array (never a shell string) and a
  restricted `GIT_ALLOW_PROTOCOL`.
- Mirrors live under `mirror_root` and deletion is refused for any path outside it.
- API access is gated by Redmine's `browse_repository` / `manage_repository`
  permissions; the overview page respects `browse_repository` per project.

## Requirements

Redmine 6.0+ (tested on 6.1.2), Ruby 3.3, Rails 7.2, and `git` on the server.

## Documentation

- [Deployment](docs/deployment.md) — install, configure `mirror_root`, enable the
  SCM, server-side git authentication, changeset sync, upgrade, uninstall.
- [Usage](docs/usage.md) — connecting repositories, the Git overview page, menu
  visibility settings, migrating from `redmine_git_remote`.
- [REST API](docs/api.md) — endpoints, parameters, authentication, examples.

## License

Licensed under the GNU General Public License v2 — the same license as Redmine.
See [LICENSE](LICENSE). Copyright (C) 2026 polumish.
