get 'projects/:id/agile_board' => 'easy_agile_board#show', :as => 'easy_agile_board'
resources :projects do
  resources :easy_sprints do
    member do
      post 'assign_issue'
    end
    collection do
      post 'unassign_issue'
    end
  end
end
