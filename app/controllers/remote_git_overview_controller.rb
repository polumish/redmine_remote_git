class RemoteGitOverviewController < ApplicationController
  before_action :require_login
  before_action :authorize_menu

  # Consolidated, cross-project overview of every RemoteGit repository the current
  # user is allowed to browse, plus the most recent changesets across them.
  def index
    scope = Repository.where(type: 'Repository::RemoteGit').includes(:project)
    unless User.current.admin?
      allowed = Project.allowed_to(User.current, :browse_repository).pluck(:id)
      scope = scope.where(project_id: allowed)
    end
    @repositories = scope.to_a

    # Last changeset date per repo (single grouped query, avoids N+1).
    repo_ids = @repositories.map(&:id)
    @last_dates  = Changeset.where(repository_id: repo_ids).group(:repository_id).maximum(:committed_on)
    @counts      = Changeset.where(repository_id: repo_ids).group(:repository_id).count
    @repositories.sort_by! { |r| @last_dates[r.id] || Time.at(0) }
    @repositories.reverse!
    @active_repositories   = @repositories.select { |r| r.project.active? }
    @archived_repositories = @repositories.reject { |r| r.project.active? }

    @recent_changesets = Changeset.where(repository_id: repo_ids)
                                  .includes(repository: :project)
                                  .order(committed_on: :desc)
                                  .limit(30)
  end

  private

  def authorize_menu
    render_403 unless RedmineRemoteGit::Menu.visible?(User.current)
  end
end
