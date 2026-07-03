require File.expand_path('../../test_helper', __FILE__)
require 'fileutils'

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
    @mirror_root = Dir.mktmpdir
    RedmineRemoteGit.settings[:mirror_root] = @mirror_root
  end

  def teardown
    FileUtils.rm_rf(@mirror_root) if @mirror_root
    super
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

  def test_show_never_leaks_credential
    # Build the Repository::RemoteGit row directly — no real git clone needed.
    # repo_create_validation checks Setting.enabled_scm; enable RemoteGit for this test.
    Setting.enabled_scm = (Setting.enabled_scm + ['RemoteGit']).uniq
    repo = Repository::RemoteGit.new(
      project:    @project,
      identifier: 'leaktest',
      url:        '/tmp/leak.git',
      root_url:   '/tmp/leak.git'
    )
    repo.save!

    src = repo.build_remote_git_source(
      source_url:  'ssh://git@h/g/r.git',
      mirror_path: '/tmp/leak.git',
      auth_type:   'https_token'
    )
    src.credential = 'glpat-SUPERSECRET-LEAKCHECK'
    src.save!

    get "/projects/#{@project.id}/git_repos/#{repo.id}.json",
      headers: { 'X-Redmine-API-Key' => @key }

    assert_response :success, "Expected 200, got #{@response.status}: #{@response.body.inspect}"
    body = @response.body
    assert_not_empty body, "Response body is empty (status=#{@response.status}, ct=#{@response.content_type})"
    json = JSON.parse(body)
    assert_equal true, json.dig('git_repo', 'has_credential'),
      'has_credential should be true'
    refute_includes body, 'glpat-SUPERSECRET-LEAKCHECK',
      'plaintext credential must never appear in the response body'
    refute_includes body, 'credential_enc',
      'encrypted credential field must never appear in the response body'
  end
end
