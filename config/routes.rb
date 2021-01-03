require 'sidekiq/web'
Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  sidekiq_web_constraint = ->(_, request) { ['::1', '127.0.0.1'].include?(request.remote_ip) || ENV['SIDEKIQ_SERVER_OPEN'].present? }
  constraints sidekiq_web_constraint do
    mount Sidekiq::Web => '/.sidekiq'
  end

  constraints subdomain: 'api' do
    get 'status' => 'site#status'
    get '/', to: redirect(subdomain: false)
    mount OParl::API, at: '/'
  end

  get 'search' => 'search#search', as: :search
  get 'search/advanced' => 'search#advanced', as: :search_advanced
  get 'search/autocomplete' => 'search#autocomplete'
  get 'search/abo', to: proc { [410, {}, ['']] }, as: :search_subscribe
  get 'opensearch.xml' => 'search#opensearch', as: :opensearch, defaults: { format: 'xml' }

  get 'recent' => 'paper#recent'

  get 'data', to: redirect('/info/daten')

  get 'info' => 'info#index'
  get 'info/daten'
  get 'info/kontakt'
  get 'info/datenschutz'
  get 'info/mitmachen'
  get 'info/spenden'
  get 'info/stilllegung', as: :obituary

  get 'static/kleineanfragen.svg', to: redirect { ActionController::Base.helpers.asset_path('kleineanfragen.svg') }

  get 'metrics' => 'metrics#show'

  get 'review' => 'review#index'
  get 'review/papers'
  get 'review/ministries'
  get 'review/late'
  get 'review/today'
  get 'review/relations'
  get 'review/scraper' => 'scraper_results#index', as: :scraper_results
  get '.scraper/:scraper_result' => 'scraper_results#show', as: :scraper_result

  get 'abo', to: redirect('/')
  post 'abo', to: proc { [410, {}, ['']] }, as: :subscription_create

  get 'm/:subscription/confirm/:confirmation_token', to: proc { [410, {}, ['']] }, as: :opt_in_confirm
  get 'm/:subscription/report/:confirmation_token', to: proc { [410, {}, ['']] }, as: :opt_in_report
  get 'm/:subscription/unsubscribe', to: proc { [410, {}, ['']] }, as: :unsubscribe

  # really short paper url used for debugging jobs
  get 'p:paper' => 'paper#redirect_by_id', constraints: { paper: /[0-9]+/ }

  get 'status' => 'site#status'

  get ':body/abo', to: proc { [410, {}, ['']] }, as: :body_subscribe
  get ':body/behoerde/:ministry' => 'ministry#show', as: :ministry
  get ':body/fraktion/:organization' => 'organization#show', as: :organization

  post ':body/:legislative_term/:paper/report', to: proc { [410, {}, ['']] }, as: :paper_send_report, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper/report', to: proc { [410, {}, ['']] }, as: :paper_report, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper/viewer' => 'paper#viewer', as: :paper_pdf_viewer, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper' => 'paper#show', as: :paper, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term' => 'legislative_term#show', as: :legislative_term, constraints: { legislative_term: /[0-9]+/ }
  get ':body' => 'body#feed', as: :body_feed, body: /[^0-9\/\.]+/, format: true
  get ':body' => 'body#show', as: :body, body: /[^0-9\/\.]+/, format: false

  root 'site#index'
end