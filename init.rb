require 'redmine'

REDMINE_REMOTE_GIT_VERSION = '0.1.0'.freeze

Redmine::Plugin.register :redmine_remote_git do
  name 'Redmine Remote Git'
  author 'polumish'
  description 'Link external git repositories (SSH/HTTPS) to projects via REST API and UI'
  version REDMINE_REMOTE_GIT_VERSION
  requires_redmine version_or_higher: '6.0.0'
end
