resources :projects, only: [] do
  resources :git_repos, only: [:index, :show, :create, :update, :destroy] do
    member { post :fetch }
  end
end
