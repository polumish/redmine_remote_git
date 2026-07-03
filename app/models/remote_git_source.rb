class RemoteGitSource < ActiveRecord::Base
  belongs_to :repository

  AUTH_TYPES = %w[none https_token].freeze
  validates :source_url, :mirror_path, presence: true
  validates :auth_type, inclusion: { in: AUTH_TYPES }

  def credential=(plain)
    self.credential_enc = RedmineRemoteGit::TokenCipher.encrypt(plain)
  end

  def credential
    RedmineRemoteGit::TokenCipher.decrypt(credential_enc)
  end

  def has_credential?
    credential_enc.present?
  end
end
