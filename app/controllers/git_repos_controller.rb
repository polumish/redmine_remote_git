class GitReposController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize_read, only: [:index, :show]
  before_action :authorize_write, only: [:create, :update, :destroy, :fetch]
  accept_api_auth :index, :show, :create, :update, :destroy, :fetch

  def index
    @repos = @project.repositories.where(type: 'Repository::RemoteGit')
    respond_to { |f| f.api }
  end

  def show
    @repo = find_repo
    respond_to { |f| f.api }
  end

  def create
    p = params.require(:remote_git).permit(:url, :identifier, :auth_type, :credential, :credential_login, :is_default)
    @repo = Repository::RemoteGit.new(project: @project,
      identifier: p[:identifier].presence || derive_identifier(p[:url]),
      is_default: p[:is_default].present?)
    @repo.clone_and_link!(source_url: p[:url], auth_type: p[:auth_type].presence || 'none',
      credential: p[:credential], credential_login: p[:credential_login])
    respond_to { |f| f.api { render action: 'show', status: :created } }
  rescue RedmineRemoteGit::UrlValidator::InvalidUrl,
         RedmineRemoteGit::RemoteGitService::GitError,
         ActiveRecord::RecordInvalid => e
    @repo&.destroy
    render_api_errors(e.message)
  end

  def update
    @repo = find_repo
    src = @repo.remote_git_source
    return render_404 if src.nil?
    p = params.require(:remote_git).permit(:auth_type, :credential, :credential_login)
    src.auth_type = p[:auth_type] if p[:auth_type].present?
    src.credential_login = p[:credential_login] if p.key?(:credential_login)
    src.credential = p[:credential] if p[:credential].present?
    src.save!
    RedmineRemoteGit::VaultBackup.mirror(@repo, src) if defined?(Vault::Key)
    respond_to { |f| f.api { render action: 'show' } }
  rescue ActiveRecord::RecordInvalid, RedmineRemoteGit::UrlValidator::InvalidUrl => e
    render_api_errors(e.message)
  end

  def destroy
    find_repo.destroy
    respond_to { |f| f.api { head :no_content } }
  end

  def fetch
    @repo = find_repo
    @repo.fetch_changesets
    respond_to { |f| f.api { render action: 'show' } }
  end

  private

  def authorize_read;  deny_access unless User.current.allowed_to?(:browse_repository, @project); end
  def authorize_write; deny_access unless User.current.allowed_to?(:manage_repository, @project); end
  def find_repo; @project.repositories.where(type: 'Repository::RemoteGit').find(params[:id]); end
  def derive_identifier(url); RedmineRemoteGit::UrlValidator.parts(url)[:repo].parameterize; end
  def render_api_errors(msg); render json: { errors: [msg] }, status: :unprocessable_entity; end
end
