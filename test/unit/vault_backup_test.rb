require File.expand_path('../../test_helper', __FILE__)

class VaultBackupTest < ActiveSupport::TestCase
  def test_noop_when_no_credential
    src = RemoteGitSource.new(auth_type: 'none')
    assert_nil RedmineRemoteGit::VaultBackup.mirror(nil, src)
  end
end
