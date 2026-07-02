require File.expand_path('../../test_helper', __FILE__)

class RemoteGitSourceTest < ActiveSupport::TestCase
  fixtures :projects, :repositories

  def test_credential_encrypted_at_rest
    s = RemoteGitSource.new(repository_id: repositories(:repositories_001).id,
                            source_url: 'ssh://git@h/g/r.git', mirror_path: '/x/r.git',
                            auth_type: 'https_token')
    s.credential = 'glpat-abc'
    s.save!
    raw = RemoteGitSource.connection.select_value(
      "SELECT credential_enc FROM remote_git_sources WHERE id=#{s.id}")
    assert raw.start_with?('rgt1:'), 'stored encrypted'
    refute_includes raw, 'glpat-abc'
    assert_equal 'glpat-abc', RemoteGitSource.find(s.id).credential
    assert RemoteGitSource.find(s.id).has_credential?
  end
end
