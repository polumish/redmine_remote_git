# Changelog

## 0.3.0 — 2026-07-03

- Overview page: text filter/search, click-to-sort columns, and a separate
  collapsible section for repositories in archived projects.
- Plugin settings to control who sees the Git top-menu entry: everyone logged in,
  administrators only, or selected groups and/or users (admins always see it).
  The overview controller enforces the same visibility.

## 0.2.0 — 2026-07-03

- Add a global **Git** top-menu entry (with a git icon) linking to a consolidated,
  cross-project overview of every RemoteGit repository the current user may browse:
  repository, project, project status, changeset count, last change, plus a
  "recent changes" list of the latest changesets across all repositories.
  Visibility respects `browse_repository` permission per project.

## 0.1.0 — 2026-07-03

Initial release.

- Link external git repositories (SSH/HTTPS) to Redmine projects via a REST API
  (`/projects/:project_id/git_repos`, CRUD + `fetch`), browsing through core
  `Repository::Git` via a `Repository::RemoteGit` SCM subclass.
- Credentials (HTTPS tokens) encrypted at rest with AES-256-GCM keyed from
  `secret_key_base` (marker `rgt1:`); write-only over the API, never serialized in
  responses, never written to a mirror's `.git/config`, injected to git only via an
  ephemeral `GIT_ASKPASS` helper.
- Strict URL validation: scheme allowlist (`https`/`ssh`/scp-form → `ssh`), shell
  metacharacter and option-injection guards, rejection of URL-embedded credentials
  and `..` path segments; all git invocations use argv arrays with
  `GIT_ALLOW_PROTOCOL=https:ssh` and `GIT_TERMINAL_PROMPT=0`.
- Bare `--mirror` clones stored outside the plugin directory under the configurable
  `mirror_root`; mirrors removed on repository destroy; deletion guarded to stay
  within `mirror_root`.
- Optional best-effort backup of the credential into the Redmine Vault plugin when
  present.
- Rake tasks for the legacy `redmine_git_remote` migration:
  `redmine_remote_git:list_orphans`, `:adopt[id]` (transaction-wrapped),
  `:uninstall_cleanup`.
