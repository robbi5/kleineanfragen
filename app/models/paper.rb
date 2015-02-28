class Paper < ActiveRecord::Base
  extend FriendlyId
  friendly_id :reference_and_title, use: :scoped, scope: [:body, :legislative_term]

  # enable search
  searchkick language: 'German',
             text_start: [:title],
             highlight: [:title, :contents],
             index_prefix: 'kleineanfragen',
             include: [:body, :paper_originators, :originator_people, :originator_organizations]

  # Fix searchkick "immense term":
  class << self
    alias_method :old_searchkick_index_options, :searchkick_index_options

    def searchkick_index_options
      o = old_searchkick_index_options
      # remove index: "not_analyzed"
      o[:mappings][:_default_][:properties]['contents'][:fields].delete('contents')
      o
    end
  end

  belongs_to :body
  has_many :paper_originators
  has_many :originator_people, through: :paper_originators, source: :originator, source_type: 'Person'
  has_many :originator_organizations, through: :paper_originators, source: :originator, source_type: 'Organization'
  has_many :paper_answerers
  has_many :answerer_people, through: :paper_answerers, source: :answerer, source_type: 'Person'
  # has_many :answerer_organizations, through: :paper_answerers, source: :answerer, source_type: 'Organization'
  has_many :answerer_ministries, through: :paper_answerers, source: :answerer, source_type: 'Ministry'

  scope :search_import, -> { includes(:body) }

  def originators
    # TODO: why is .delete_if(&:nil?) needed, why can be an originator nil?
    paper_originators.sort_by { |org| org.originator_type == 'Person' ? 1 : 2 }.collect(&:originator).delete_if(&:nil?)
  end

  def answerers
    paper_answerers.sort_by { |answerer| answerer.answerer_type == 'Person' ? 1 : 2 }.collect(&:answerer)
  end

  validates :reference, uniqueness: { scope: [:body_id, :legislative_term] }

  # friendly id helpers

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def reference_and_title
    [
      [:reference, :title]
    ]
  end

  def normalize_friendly_id(value)
    value.to_s.gsub('&', 'und').parameterize.truncate(120, separator: '-', omission: '')
  end

  # searchkick helpers

  def search_data
    {
      body: body.state,
      legislative_term: legislative_term,
      reference: reference,
      title: title,
      contents: contents,
      contains_table: contains_table,
      published_at: published_at
    }
  end

  def autocomplete_data
    {
      title: title,
      reference: full_reference,
      source: body.name,
      url: Rails.application.routes.url_helpers.paper_path(body, legislative_term, self)
    }
  end

  def full_reference
    legislative_term.to_s + '/' + reference.to_s
  end

  def path
    File.join(body.folder_name, legislative_term.to_s, reference.to_s + '.pdf')
  end

  def thumbnail_path
    File.join(body.folder_name, legislative_term.to_s, reference.to_s + '.png')
  end

  def local_path
    Rails.configuration.x.paper_storage.join(path)
  end

  def public_url
    AppStorage.bucket.files.head(path).try(:public_url)
  rescue => error
    Rails.logger.warn "Cannot get public_url of paper [#{body.state} #{full_reference}]: #{error}"
    nil
  end

  def thumbnail_url
    AppStorage.bucket.files.head(thumbnail_path).try(:public_url)
  rescue => error
    Rails.logger.warn "Cannot get public_url of thumbnail of paper [#{body.state} #{full_reference}]: #{error}"
    nil
  end

  def description
    desc = []
    desc << "kleine Anfrage #{full_reference} aus #{body.name}. "
    if originator_people.size > 0
      desc << "Eingereicht von #{originator_people.collect(&:name).join(', ')}, " +
              "#{originator_organizations.collect(&:name).join(', ')}. "
    end
    desc << "#{page_count} #{ActionController::Base.helpers.t(:pages, count: page_count)}." if page_count.present?
    desc.join('')
  end

  def originators_parties=(parties)
    parties.each do |party|
      party = normalize(party, 'parties')
      Rails.logger.debug "+ Originator (Party): #{party}" # TODO: refactor
      org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
      originator_organizations << org unless originator_organizations.include? org
    end
  end

  def originators_people=(people)
    people.each do |name|
      name = normalize(name, 'people', body)
      Rails.logger.debug "+ Originator (Person): #{name}" # TODO: refactor
      person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
      originator_people << person unless originator_people.include? person
    end
  end

  def originators=(originators)
    self.originators_parties = originators[:parties] unless originators[:parties].blank?
    self.originators_people = originators[:people] unless originators[:people].blank?
  end

  def answerers_ministries=(ministries)
    ministries.each do |name|
      ministry = Ministry.where(body: body).where('lower(short_name) = ?', name.mb_chars.downcase.to_s).first
      if ministry.nil?
        name = normalize(name, 'ministries', body)
        ministry = Ministry.where(body: body)
                   .where('lower(name) = ?', name.mb_chars.downcase.to_s)
                   .first_or_create(body: body, name: name)
      end
      Rails.logger.debug "+ Ministry: #{ministry.name}" # TODO: refactor
      answerer_ministries << ministry unless answerer_ministries.include? ministry
    end
  end

  def answerers=(answerers)
    self.answerers_ministries = answerers[:ministries] unless answerers[:ministries].blank?
  end

  def problems
    p = []
    p << :wrong_published_at if published_at > Date.today
    p << :missing_page_count if page_count.nil?
    p << :missing_originator_people if originator_people.size == 0
    p << :missing_originator_organizations if originator_organizations.size == 0
    p << :missing_answerers if paper_answerers.size == 0
    p
  end

  private

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    Nomenklatura::Dataset.new("ka-#{prefix}" + (!body.nil? ? "-#{body.state.downcase}" : '')).lookup(name)
  end
end
