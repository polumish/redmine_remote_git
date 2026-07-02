require File.expand_path('../../test_helper', __FILE__)
require 'minitest/mock'
require 'tmpdir'; require 'fileutils'

class RemoteGitServiceTest < ActiveSupport::TestCase
  fixtures :projects, :repositories

  # Trigger Zeitwerk autoload of remote_git_service.rb so RedmineRemoteGit.settings
  # is available when setup runs (same pattern as url_validator_test.rb uses V = ...).
  SVC = RedmineRemoteGit::RemoteGitService

  def setup
    @tmp = Dir.mktmpdir
    @remote = File.join(@tmp, 'origin.git')
    system('git', 'init', '-q', '--bare', @remote)
    work = File.join(@tmp, 'work')
    system('git', 'clone', '-q', @remote, work)
    File.write(File.join(work, 'a.txt'), 'hi')
    system('git', '-C', work, 'add', '.')
    system({ 'GIT_AUTHOR_NAME' => 't', 'GIT_AUTHOR_EMAIL' => 't@t', 'GIT_COMMITTER_NAME' => 't', 'GIT_COMMITTER_EMAIL' => 't@t' },
           'git', '-C', work, 'commit', '-q', '-m', 'init')
    system('git', '-C', work, 'push', '-q', 'origin', 'HEAD:refs/heads/main')
    RedmineRemoteGit.settings[:mirror_root] = @tmp
  end

  def teardown; FileUtils.remove_entry(@tmp); end

  def test_clone_creates_bare_mirror
    # allow file:// only in test by stubbing validator normalize
    # NOTE: src construction is inside the stub block so mirror_path_for("file://...")
    # is called while normalize is already stubbed (file:// would raise InvalidUrl otherwise)
    RedmineRemoteGit::UrlValidator.stub(:normalize, "file://#{@remote}") do
      src = RemoteGitSource.new(repository_id: repositories(:repositories_001).id,
        source_url: "ssh://x", mirror_path: SVC.mirror_path_for("file://#{@remote}"),
        auth_type: 'none')
      svc = SVC.new(src)
      svc.clone_mirror!("file://#{@remote}")
      assert File.directory?(src.mirror_path), 'mirror dir exists'
      assert File.exist?(File.join(src.mirror_path, 'HEAD')), 'bare repo'
    end
  end
end
