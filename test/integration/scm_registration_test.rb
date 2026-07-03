require File.expand_path('../../test_helper', __FILE__)

class ScmRegistrationTest < ActiveSupport::TestCase
  def test_remote_git_scm_registered
    assert_includes Redmine::Scm::Base.all, 'RemoteGit'
  end
end
