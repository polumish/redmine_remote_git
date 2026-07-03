require File.expand_path('../../test_helper', __FILE__)

class OrphanAdoptTest < ActiveSupport::TestCase
  def test_recover_url_from_old_path
    path = '/var/www/redmine/plugins/redmine_git_remote/repos/git.half.net.ua/5022/polumish/pmg.ua-new'
    assert_equal 'ssh://git@git.half.net.ua:5022/polumish/pmg.ua-new.git',
      RedmineRemoteGit::OrphanTools.recover_url(path)
  end
end
