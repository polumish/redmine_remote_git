require 'uri'

module RedmineRemoteGit
  module UrlValidator
    class InvalidUrl < StandardError; end

    SCP = %r{\A(?<user>[a-z0-9._-]+)@(?<host>[a-z0-9.-]+):(?<path>[A-Za-z0-9._/-]+)\z}i
    HOST = /\A[a-z0-9.-]+\z/i
    PATH = %r{\A/[A-Za-z0-9._/-]+\z}
    META = /[\s;&|`$<>()\\'"]|--/  # shell metachars or option-injection

    def self.normalize(url)
      raise InvalidUrl, 'blank' if url.nil? || url.strip.empty?
      url = url.strip
      raise InvalidUrl, "unsafe chars: #{url}" if url =~ META
      if (m = url.match(SCP))
        return "ssh://#{m[:user]}@#{m[:host]}/#{m[:path]}"
      end
      uri = begin
        URI.parse(url)
      rescue URI::InvalidURIError
        raise InvalidUrl, url
      end
      unless %w[ssh https].include?(uri.scheme)
        raise InvalidUrl, "scheme not allowed: #{uri.scheme.inspect}"
      end
      raise InvalidUrl, "bad host: #{uri.host}" unless uri.host.to_s =~ HOST
      raise InvalidUrl, "bad path: #{uri.path}" unless uri.path.to_s =~ PATH
      url
    end

    def self.parts(url)
      norm = normalize(url)
      uri = URI.parse(norm.sub(%r{\Assh://[^/@]+@}, 'ssh://'))
      segs = uri.path.sub(%r{\.git\z}, '').split('/').reject(&:empty?)
      { host: uri.host, group: segs[-2], repo: segs[-1] }
    end
  end
end
