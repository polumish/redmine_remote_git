class Repository::RemoteGit < Repository::Git
  has_one :remote_git_source, foreign_key: :repository_id, dependent: :destroy

  before_destroy :remove_mirror, prepend: true

  def self.scm_name
    'RemoteGit'
  end

  # Orchestration invoked by the API/UI on create.
  def clone_and_link!(source_url:, auth_type: 'none', credential: nil, credential_login: nil)
    safe = RedmineRemoteGit::UrlValidator.normalize(source_url)
    mirror = RedmineRemoteGit::RemoteGitService.mirror_path_for(safe)
    self.url = mirror
    self.root_url = mirror
    save! # core Repository validations (identifier etc.)
    src = build_remote_git_source(source_url: safe, mirror_path: mirror,
      auth_type: auth_type, credential_login: credential_login)
    src.credential = credential if auth_type == 'https_token' && credential.present?
    src.save!
    RedmineRemoteGit::RemoteGitService.new(src).clone_mirror!(safe)
    RedmineRemoteGit::VaultBackup.mirror(self, src) if defined?(Vault::Key)
    self
  end

  def fetch_changesets
    src = remote_git_source
    RedmineRemoteGit::RemoteGitService.new(src).fetch! if src
    super
  end

  private

  def remove_mirror
    src = remote_git_source
    return unless src
    RedmineRemoteGit::RemoteGitService.new(src).destroy_mirror!
  rescue => e
    Rails.logger.warn("remote_git: mirror cleanup failed: #{e.message}")
  end
end
