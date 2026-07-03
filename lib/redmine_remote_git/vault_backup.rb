module RedmineRemoteGit
  module VaultBackup
    def self.mirror(repository, source)
      return nil unless defined?(Vault::Key)
      return nil unless source&.has_credential?
      p = UrlValidator.parts(source.source_url)
      name = "git token: #{p[:host]}/#{p[:group]}/#{p[:repo]}"
      key = source.vault_key_id && Vault::Key.find_by(id: source.vault_key_id)
      key ||= Vault::Key.new(project: repository.project)
      key.name = name
      key.body = source.credential
      key.sensitive = true if key.respond_to?(:sensitive=)
      key.save!
      source.update_columns(vault_key_id: key.id)
      key.id
    rescue => e
      Rails.logger.warn("remote_git: vault backup failed: #{e.message}")
      nil
    end
  end
end
