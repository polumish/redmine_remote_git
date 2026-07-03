resources :projects, only: [] do
  resources :git_repos, only: [:index, :show, :create, :update, :destroy] do
    member { post :fetch }
  end
end

get 'remote_git', to: 'remote_git_overview#index', as: 'remote_git_overview'
