Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  get 'search' => 'paper#search'
  get 'search/autocomplete' => 'paper#autocomplete'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  get ':body/:legislative_term/:paper' => 'paper#show', as: :paper, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term' => 'legislative_term#show', as: :legislative_term, constraints: { legislative_term: /[0-9]+/ }
  get ':body' => 'body#show', as: :body, body: /[^0-9\/]+/, format: false

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # You can have the root of your site routed with "root"
  root 'site#index'

end
