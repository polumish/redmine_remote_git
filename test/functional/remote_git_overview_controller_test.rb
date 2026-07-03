require File.expand_path('../../test_helper', __FILE__)

class RemoteGitOverviewControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :enabled_modules, :repositories, :changesets, :groups_users

  def setup
    Setting.enabled_scm = (Setting.enabled_scm + ['RemoteGit']).uniq
    @repo = Repository::RemoteGit.new(project: Project.find(1), identifier: 'ovtest',
                                      url: '/tmp/ov.git', root_url: '/tmp/ov.git')
    @repo.save!
  end

  def teardown
    Setting.plugin_redmine_remote_git = {}
  end

  def test_index_requires_login
    get :index
    assert_response :redirect
  end

  def test_index_lists_remote_git_repos_for_admin
    @request.session[:user_id] = 1 # admin
    get :index
    assert_response :success
    assert_select 'h2', /Git/
    assert_select 'table.remote-git-repos a', text: 'ovtest'
  end

  def test_index_hides_repos_from_projects_user_cannot_browse
    Project.find(1).update_column(:is_public, false)
    @request.session[:user_id] = 7
    get :index
    assert_response :success
    assert_select 'table.remote-git-repos a', text: 'ovtest', count: 0
  end

  def test_menu_hidden_for_non_admin_when_admins_only
    Setting.plugin_redmine_remote_git = { 'menu_visibility' => 'admins' }
    @request.session[:user_id] = 2 # jsmith, not admin
    get :index
    assert_response :forbidden
  end

  def test_menu_visible_for_admin_when_admins_only
    Setting.plugin_redmine_remote_git = { 'menu_visibility' => 'admins' }
    @request.session[:user_id] = 1
    get :index
    assert_response :success
  end

  def test_menu_visible_for_explicitly_selected_user
    Setting.plugin_redmine_remote_git = { 'menu_visibility' => 'selected', 'menu_user_ids' => [2] }
    @request.session[:user_id] = 2
    get :index
    assert_response :success
  end

  def test_menu_hidden_for_non_selected_user
    Setting.plugin_redmine_remote_git = { 'menu_visibility' => 'selected', 'menu_user_ids' => [999] }
    @request.session[:user_id] = 2
    get :index
    assert_response :forbidden
  end
end
