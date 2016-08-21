require 'resque/server'

Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resque_web_constraint = ->(_, request) { ['::1', '127.0.0.1'].include?(request.remote_ip) || ENV['RESQUE_SERVER_OPEN'].present? }
  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/.resque'
  end

  constraints subdomain: 'api' do
    mount OParl::API, at: '/'
  end

  get 'search' => 'search#search', as: :search
  get 'search/advanced' => 'search#advanced', as: :search_advanced
  get 'search/autocomplete' => 'search#autocomplete'
  get 'search/abo' => 'search#subscribe', as: :search_subscribe
  get 'opensearch.xml' => 'search#opensearch', as: :opensearch, defaults: { format: 'xml' }

  get 'recent' => 'paper#recent'

  get 'data', to: redirect('/info/daten')

  get 'info' => 'info#index'
  get 'info/daten'
  get 'info/kontakt'
  get 'info/datenschutz'
  get 'info/mitmachen'
  get 'info/spenden'

  get 'static/kleineanfragen.svg', to: redirect { ActionController::Base.helpers.asset_path('kleineanfragen.svg') }

  get 'metrics' => 'metrics#show'

  get 'review' => 'review#index'
  get 'review/papers'
  get 'review/ministries'
  get 'review/today'
  get 'review/relations'
  get 'review/scraper' => 'scraper_results#index', as: :scraper_results
  get '.scraper/:scraper_result' => 'scraper_results#show', as: :scraper_result

  post 'webhook/incoming_email' => 'griddler/emails#create', constraints: EmailTokenConstraint

  get 'abo', to: redirect('/')
  post 'abo' => 'subscription#subscribe', as: :subscription_create

  get 'm/:subscription/confirm/:confirmation_token' => 'opt_in#confirm', as: :opt_in_confirm
  get 'm/:subscription/report/:confirmation_token' => 'opt_in#report', as: :opt_in_report
  get 'm/:subscription/unsubscribe' => 'subscription#unsubscribe', as: :unsubscribe

  # really short paper url used for debugging jobs
  get 'p:paper' => 'paper#redirect_by_id', constraints: { paper: /[0-9]+/ }

  get 'status' => 'site#status'

  get ':body/abo' => 'body#subscribe', as: :body_subscribe
  get ':body/behoerde/:ministry' => 'ministry#show', as: :ministry
  get ':body/fraktion/:organization' => 'organization#show', as: :organization

  post ':body/:legislative_term/:paper/report' => 'paper#send_report', as: :paper_send_report, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper/report' => 'paper#report', as: :paper_report, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper/viewer' => 'paper#viewer', as: :paper_pdf_viewer, constraints: { legislative_term: /[0-9]+/ }
  put ':body/:legislative_term/:paper' => 'paper#update', format: :txt
  get ':body/:legislative_term/:paper' => 'paper#show', as: :paper, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term' => 'legislative_term#show', as: :legislative_term, constraints: { legislative_term: /[0-9]+/ }
  get ':body' => 'body#feed', as: :body_feed, body: /[^0-9\/\.]+/, format: true
  get ':body' => 'body#show', as: :body, body: /[^0-9\/\.]+/, format: false

  root 'site#index'
end