require 'openssl'
require 'base64'

module RedmineRemoteGit
  module TokenCipher
    MARKER = 'rgt1:'.freeze

    def self.key
      OpenSSL::Digest::SHA256.digest("redmine_remote_git:#{Rails.application.secret_key_base}")
    end

    def self.encrypt(plaintext)
      return nil if plaintext.nil? || plaintext.to_s.empty?
      cipher = OpenSSL::Cipher.new('aes-256-gcm').encrypt
      cipher.key = key
      iv = cipher.random_iv
      ct = cipher.update(plaintext.to_s) + cipher.final
      MARKER + Base64.strict_encode64(iv + cipher.auth_tag + ct)
    end

    def self.decrypt(stored)
      return nil if stored.nil? || !stored.start_with?(MARKER)
      raw = Base64.strict_decode64(stored[MARKER.length..])
      iv = raw[0, 12]; tag = raw[12, 16]; ct = raw[28..]
      cipher = OpenSSL::Cipher.new('aes-256-gcm').decrypt
      cipher.key = key; cipher.iv = iv; cipher.auth_tag = tag
      cipher.update(ct) + cipher.final
    end
  end
end
