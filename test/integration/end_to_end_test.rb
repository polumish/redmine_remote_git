require File.expand_path('../../test_helper', __FILE__)
require 'minitest/mock'
require 'tmpdir'; require 'fileutils'

class EndToEndTest < ActiveSupport::TestCase
  fixtures :projects

  # Trigger Zeitwerk autoload of remote_git_service.rb so RedmineRemoteGit.settings
  # is available before the test body runs (same pattern as remote_git_service_test.rb).
  SVC = RedmineRemoteGit::RemoteGitService

  def setup
    Setting.enabled_scm = (Setting.enabled_scm + ['RemoteGit']).uniq
  end

  def test_create_fetch_delete_roundtrip
    tmp = Dir.mktmpdir
    remote = File.join(tmp, 'o.git'); system('git', 'init', '-q', '--bare', remote)
    w = File.join(tmp, 'w'); system('git', 'clone', '-q', remote, w)
    File.write(File.join(w, 'f'), 'x'); system('git', '-C', w, 'add', '.')
    system({ 'GIT_AUTHOR_NAME' => 't', 'GIT_AUTHOR_EMAIL' => 't@t',
             'GIT_COMMITTER_NAME' => 't', 'GIT_COMMITTER_EMAIL' => 't@t' },
           'git', '-C', w, 'commit', '-q', '-m', 'i')
    system('git', '-C', w, 'push', '-q', 'origin', 'HEAD:refs/heads/main')

    RedmineRemoteGit.settings[:mirror_root] = tmp
    RedmineRemoteGit.settings[:git_allow_protocol] = 'https:ssh:file'

    RedmineRemoteGit::UrlValidator.stub(:normalize, "file://#{remote}") do
      repo = Repository::RemoteGit.new(project: projects(:projects_001), identifier: 'e2e')
      repo.clone_and_link!(source_url: "file://#{remote}")

      assert File.directory?(repo.remote_git_source.mirror_path), 'mirror dir exists after clone'
      assert File.exist?(File.join(repo.remote_git_source.mirror_path, 'HEAD')), 'bare mirror has HEAD'

      # fetch_changesets exercises the fetch path (should not raise)
      assert_nothing_raised { repo.fetch_changesets }

      path = repo.remote_git_source.mirror_path
      repo.destroy
      refute File.exist?(path), 'mirror removed on destroy'
    end
  ensure
    FileUtils.remove_entry(tmp) if tmp && File.exist?(tmp)
  end
end
