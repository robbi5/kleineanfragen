require 'resque/server'

Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resque_web_constraint = ->(_, request) { ['::1', '127.0.0.1'].include?(request.remote_ip) || ENV['RESQUE_SERVER_OPEN'].present? }
  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/.resque'
  end

  get 'search' => 'paper#search', as: :search
  get 'search/autocomplete' => 'paper#autocomplete'

  get 'recent' => 'paper#recent'

  get 'info' => 'info#index'
  get 'info/daten'
  get 'info/kontakt'
  get 'info/mitmachen'

  get 'review' => 'review#index'
  get 'review/papers'
  get 'review/ministries'
  get 'review/today'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # really short paper url used for debugging jobs
  get 'p:paper' => 'paper#redirect_by_id', constraints: { paper: /[0-9]+/ }

  get ':body/behoerde/:ministry' => 'ministry#show', as: :ministry

  get ':body/:legislative_term/:paper/viewer' => 'paper#viewer', as: :paper_pdf_viewer, constraints: { legislative_term: /[0-9]+/ }
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