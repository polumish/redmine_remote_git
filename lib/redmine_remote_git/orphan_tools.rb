module RedmineRemoteGit
  module OrphanTools
    # .../repos/<host>/[<port>/]<group>/<repo>  ->  ssh URL
    def self.recover_url(path)
      segs = path.split('/repos/', 2).last.to_s.split('/').reject(&:empty?)
      host = segs[0]
      rest = segs[1..]
      port = (rest.first =~ /\A\d+\z/) ? rest.shift : nil
      group = rest[0]; repo = rest[1]
      hostport = port ? "#{host}:#{port}" : host
      "ssh://git@#{hostport}/#{group}/#{repo}.git"
    end
  end
end
