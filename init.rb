require 'redmine'
require_relative 'lib/redmine_remote_git/token_cipher'
require_relative 'lib/redmine_remote_git/url_validator'
require_relative 'lib/redmine_remote_git/remote_git_service'
require_relative 'lib/redmine_remote_git/vault_backup'
require_relative 'lib/redmine_remote_git/hooks'

REDMINE_REMOTE_GIT_VERSION = '0.2.0'.freeze

Redmine::Plugin.register :redmine_remote_git do
  name 'Redmine Remote Git'
  author 'polumish'
  description 'Link external git repositories (SSH/HTTPS) to projects via REST API and UI'
  version REDMINE_REMOTE_GIT_VERSION
  requires_redmine version_or_higher: '6.0.0'
  settings default: { 'mirror_root' => '/var/www/redmine/git_mirrors' }, partial: ''

  menu :top_menu, :remote_git_overview,
       { controller: 'remote_git_overview', action: 'index' },
       caption: :label_remote_git_menu,
       if: proc { User.current.logged? },
       html: { class: 'remote-git-menu' }
end

Rails.application.config.after_initialize do
  Redmine::Scm::Base.add 'RemoteGit'
end
