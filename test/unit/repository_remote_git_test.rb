require File.expand_path('../../test_helper', __FILE__)

class RepositoryRemoteGitTest < ActiveSupport::TestCase
  fixtures :projects

  def test_scm_name_and_source_assoc
    assert_equal 'RemoteGit', Repository::RemoteGit.scm_name
    r = Repository::RemoteGit.new(project: projects(:projects_001), identifier: 'x')
    assert r.respond_to?(:remote_git_source)
  end
end
