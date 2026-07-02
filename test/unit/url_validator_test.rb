require File.expand_path('../../test_helper', __FILE__)

class UrlValidatorTest < ActiveSupport::TestCase
  V = RedmineRemoteGit::UrlValidator

  def test_accepts_ssh_and_https
    assert_equal 'ssh://git@git.half.net.ua:5022/redmine/remote-git.git',
      V.normalize('ssh://git@git.half.net.ua:5022/redmine/remote-git.git')
    assert_equal 'https://github.com/dergachev/redmine_git_remote.git',
      V.normalize('https://github.com/dergachev/redmine_git_remote.git')
  end

  def test_rewrites_scp_form_to_ssh
    assert_equal 'ssh://git@github.com/user/repo.git',
      V.normalize('git@github.com:user/repo.git')
  end

  def test_rejects_dangerous
    %w[
      ext::sh\ -c\ id
      file:///etc/passwd
      git://insecure/repo.git
      --upload-pack=touch\ /tmp/x
      https://h/repo.git;id
      https://h/repo`whoami`.git
    ].each do |bad|
      assert_raises(V::InvalidUrl, "must reject #{bad.inspect}") { V.normalize(bad) }
    end
  end

  def test_parts
    p = V.parts('ssh://git@git.half.net.ua:5022/redmine/remote-git.git')
    assert_equal 'git.half.net.ua', p[:host]
    assert_equal 'redmine',         p[:group]
    assert_equal 'remote-git',      p[:repo]
  end
end
