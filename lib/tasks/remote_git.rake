require_relative '../redmine_remote_git/orphan_tools'
namespace :redmine_remote_git do
  desc 'List stale GitRemote repositories'
  task list_orphans: :environment do
    Repository.where(type: 'Repository::GitRemote').find_each do |r|
      puts "##{r.id} project=#{r.project_id} url=#{r.url} -> #{RedmineRemoteGit::OrphanTools.recover_url(r.url.to_s)}"
    end
  end

  desc 'Adopt one orphan by repository id as RemoteGit'
  task :adopt, [:id] => :environment do |_t, args|
    old = Repository.where(type: 'Repository::GitRemote').find(args[:id])
    url = RedmineRemoteGit::OrphanTools.recover_url(old.url.to_s)
    proj = old.project; ident = old.identifier
    ActiveRecord::Base.transaction do
      old.destroy
      Repository::RemoteGit.new(project: proj, identifier: ident).clone_and_link!(source_url: url)
    end
    puts "Adopted ##{args[:id]} -> #{url}"
  end

  desc 'Destroy all RemoteGit repos (removes mirrors) before uninstall'
  task uninstall_cleanup: :environment do
    Repository.where(type: 'Repository::RemoteGit').find_each(&:destroy)
    puts 'RemoteGit repositories removed.'
  end
end
