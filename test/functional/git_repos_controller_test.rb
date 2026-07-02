require File.expand_path('../../test_helper', __FILE__)

class GitReposControllerTest < Redmine::ApiTest::Base
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules

  # Trigger autoload of remote_git_service.rb so RedmineRemoteGit.settings is
  # available in setup (eager_load=false in test env; same pattern as unit tests).
  SVC = RedmineRemoteGit::RemoteGitService

  def setup
    super # enables Setting.rest_api_enabled = '1' via Redmine::ApiTest::Base
    @project = projects(:projects_001)
    EnabledModule.create!(project: @project, name: 'repository') unless @project.module_enabled?(:repository)
    @key = User.find(1).api_key
    RedmineRemoteGit.settings[:mirror_root] = Dir.mktmpdir
  end

  def test_create_rejects_bad_url
    post "/projects/#{@project.id}/git_repos.json",
      params: { remote_git: { url: 'ext::sh -c id' } },
      headers: { 'X-Redmine-API-Key' => @key }
    assert_response :unprocessable_entity
  end

  def test_create_requires_permission
    post "/projects/#{@project.id}/git_repos.json",
      params: { remote_git: { url: 'ssh://git@h/g/r.git' } },
      headers: { 'X-Redmine-API-Key' => User.find(7).api_key } # non-manager
    assert_response :forbidden
  end
end
