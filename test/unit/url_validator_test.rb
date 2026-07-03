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

  def test_rejects_embedded_credentials
    # C1: URL-embedded passwords must be refused
    [
      'https://user:ghp_SECRET@github.com/org/repo.git',
      'ssh://git:pass@gitlab.com/g/r.git',
    ].each do |bad|
      assert_raises(V::InvalidUrl, "must reject credential URL #{bad.inspect}") { V.normalize(bad) }
    end
  end

  def test_rejects_dotdot_path_escape
    # I1: .. in host or path must be refused
    [
      'ssh://git@../../repo.git',
      'https://h/../../etc/passwd',
    ].each do |bad|
      assert_raises(V::InvalidUrl, "must reject .. escape #{bad.inspect}") { V.normalize(bad) }
    end
  end

  def test_accepts_bare_user_at_host
    # bare git@ (no colon = no password) must still be accepted by the URI branch
    assert_equal 'ssh://git@git.half.net.ua:5022/redmine/remote-git.git',
      V.normalize('ssh://git@git.half.net.ua:5022/redmine/remote-git.git')
    assert_equal 'https://github.com/dergachev/redmine_git_remote.git',
      V.normalize('https://github.com/dergachev/redmine_git_remote.git')
  end

  def test_parts
    p = V.parts('ssh://git@git.half.net.ua:5022/redmine/remote-git.git')
    assert_equal 'git.half.net.ua', p[:host]
    assert_equal 'redmine',         p[:group]
    assert_equal 'remote-git',      p[:repo]
  end
end
