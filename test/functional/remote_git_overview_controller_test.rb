require File.expand_path('../../test_helper', __FILE__)

class RemoteGitOverviewControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :enabled_modules, :repositories, :changesets

  def setup
    Setting.enabled_scm = (Setting.enabled_scm + ['RemoteGit']).uniq
    @repo = Repository::RemoteGit.new(project: Project.find(1), identifier: 'ovtest',
                                      url: '/tmp/ov.git', root_url: '/tmp/ov.git')
    @repo.save!
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
    # make project 1 private; user 7 is not a member -> must not see its repo
    Project.find(1).update_column(:is_public, false)
    @request.session[:user_id] = 7
    get :index
    assert_response :success
    assert_select 'table.remote-git-repos a', text: 'ovtest', count: 0
  end
end
