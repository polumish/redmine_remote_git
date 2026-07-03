# Deployment

## Requirements

- Redmine **6.0** or newer (tested on 6.1.2).
- Ruby 3.3, Rails 7.2.
- `git` available on the Redmine server (the plugin shells out to it).
- Network access from the Redmine server to the git host(s) you want to mirror.

## Install

Run as the OS user that owns the Redmine tree (examples assume `www-data` and
`/var/www/redmine`).

```bash
cd /var/www/redmine/plugins
git clone <this-repo-url> redmine_remote_git
chown -R www-data:www-data redmine_remote_git

cd /var/www/redmine
sudo -u www-data RAILS_ENV=production bin/rails redmine:plugins:migrate NAME=redmine_remote_git
```

Restart the application server (Passenger: `touch tmp/restart.txt`; Puma/systemd:
restart the service).

## Configure the mirror directory

The plugin clones a bare `--mirror` of each repository and browses it locally.
Mirrors are stored **outside** the plugin directory, under `mirror_root`
(default `/var/www/redmine/git_mirrors`).

Point `mirror_root` at a partition with enough free space (git mirrors can be
large). Set it in **Administration → Plugins → Redmine Remote Git**, or from the
console:

```bash
sudo -u www-data RAILS_ENV=production bin/rails runner \
  "s = (Setting.plugin_redmine_remote_git || {}).to_h.merge('mirror_root' => '/opt/git_mirrors'); Setting.plugin_redmine_remote_git = s"
mkdir -p /opt/git_mirrors && chown www-data:www-data /opt/git_mirrors
```

## Enable the SCM

Add `RemoteGit` to the enabled SCM list:

```bash
sudo -u www-data RAILS_ENV=production bin/rails runner \
  "Setting.enabled_scm = (Setting.enabled_scm | ['RemoteGit'])"
```

## Server-side git authentication

Cloning/fetching runs as the Redmine OS user (e.g. `www-data`). Provide it with
credentials for your git host in one of two ways:

- **SSH (recommended for internal hosts):** give the Redmine user an SSH key that
  is authorized (read-only is enough) on the git host, and add the host to its
  `known_hosts`. Repositories are then added with `auth_type=none`. A dedicated
  read-only deploy key or service account is the safest choice.

  ```
  # ~<redmine-user>/.ssh/config
  Host git.example.com
    Port 22
    User git
    IdentityFile ~/.ssh/id_ed25519
  ```

- **HTTPS token (per repository):** add the repository with `auth_type=https_token`
  and a token. The token is encrypted at rest and injected to git only through a
  temporary `GIT_ASKPASS` helper; it is never written to the mirror config.

## Plugin assets

Redmine mirrors plugin assets to `public/plugin_assets/` on boot. If the top-menu
icon or the overview page styling does not load after an upgrade, copy the assets
manually and restart:

```bash
A=/var/www/redmine/public/plugin_assets/redmine_remote_git
mkdir -p "$A/stylesheets" "$A/javascripts"
cp plugins/redmine_remote_git/assets/stylesheets/*.css "$A/stylesheets/"
cp plugins/redmine_remote_git/assets/javascripts/*.js  "$A/javascripts/"
chown -R www-data:www-data "$A"
```

## Keeping changesets up to date

Redmine imports commits when `Repository.fetch_changesets` runs. Add a cron job so
mirrors are fetched from their remotes and imported periodically:

```cron
*/10 * * * * www-data HOME=/var/www bash -lc 'cd /var/www/redmine && RAILS_ENV=production bin/rails runner "Repository.fetch_changesets"'
```

`HOME` must point at the Redmine user's home so the SSH key is found. With
`autofetch_changesets` enabled, repositories also refresh when their page is
viewed. You can trigger an immediate fetch for one repository through the API
(`POST .../git_repos/:id/fetch`).

## Upgrading

```bash
cd /var/www/redmine/plugins/redmine_remote_git && git pull
chown -R www-data:www-data .
cd /var/www/redmine
sudo -u www-data RAILS_ENV=production bin/rails redmine:plugins:migrate NAME=redmine_remote_git
# copy assets (see above), then restart the app server
```

## Uninstall

```bash
# remove all RemoteGit repositories (also deletes their mirrors), then the plugin
sudo -u www-data RAILS_ENV=production bin/rails redmine_remote_git:uninstall_cleanup
sudo -u www-data RAILS_ENV=production bin/rails redmine:plugins:migrate NAME=redmine_remote_git VERSION=0
rm -rf plugins/redmine_remote_git
# restart the app server
```
