require 'open3'; require 'fileutils'; require 'shellwords'; require 'tempfile'

module RedmineRemoteGit
  @settings = {}
  def self.settings
    @settings
  end

  class RemoteGitService
    class GitError < StandardError; end

    def self.mirror_root
      RedmineRemoteGit.settings[:mirror_root].presence || '/var/www/redmine/git_mirrors'
    end

    def self.mirror_path_for(url)
      p = UrlValidator.parts(url)
      File.join(mirror_root, p[:host], p[:group].to_s, "#{p[:repo]}.git")
    end

    def initialize(source)
      @source = source
    end

    def clone_mirror!(url)
      safe = UrlValidator.normalize(url)
      path = @source.mirror_path
      FileUtils.mkdir_p(File.dirname(path))
      run_git('clone', '--mirror', '--', safe, path)
    end

    def fetch!
      run_git('-C', @source.mirror_path, 'fetch', '--prune')
      @source.update_columns(last_fetch_at: Time.now, last_error: nil)
    end

    def destroy_mirror!
      path = @source.mirror_path.to_s
      root = File.expand_path(self.class.mirror_root)
      full = File.expand_path(path)
      raise GitError, 'refusing to delete outside mirror_root' unless full.start_with?(root + '/')
      FileUtils.remove_entry(full) if File.directory?(full)
    end

    private

    def run_git(*args)
      env = { 'GIT_ALLOW_PROTOCOL' => 'https:ssh:file', 'GIT_TERMINAL_PROMPT' => '0' }
      env.merge!(askpass_env) if @source.auth_type == 'https_token' && @source.has_credential?
      out, err, st = Open3.capture3(env, 'git', *args)
      unless st.success?
        @source.update_columns(last_error: err.to_s.strip[0, 2000]) if @source.persisted?
        raise GitError, err.to_s.strip
      end
      out
    ensure
      cleanup_askpass
    end

    def askpass_env
      @askpass = Tempfile.new(['rgt-askpass', '.sh'])
      @askpass.write("#!/bin/sh\ncase \"$1\" in *Username*) echo \"$RGT_LOGIN\";; *) echo \"$RGT_TOKEN\";; esac\n")
      @askpass.close; File.chmod(0o700, @askpass.path)
      { 'GIT_ASKPASS' => @askpass.path,
        'RGT_LOGIN' => (@source.credential_login.presence || 'oauth2'),
        'RGT_TOKEN' => @source.credential.to_s }
    end

    def cleanup_askpass
      @askpass&.unlink rescue nil
      @askpass = nil
    end
  end
end
