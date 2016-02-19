class Paper < ActiveRecord::Base
  extend FriendlyId
  friendly_id :reference_and_title, use: :scoped, scope: [:body, :legislative_term]

  DOCTYPES = ['minor', 'major', 'written']
  DOCTYPE_MINOR_INTERPELLATION = 'minor'
  DOCTYPE_MAJOR_INTERPELLATION = 'major'
  DOCTYPE_WRITTEN_INTERPELLATION = 'written'

  # enable search
  searchkick language: 'german',
             text_start: [:title],
             word_start: [:title],
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
      # replace & by und - https://github.com/ankane/searchkick/commit/f8714d22778e450a5eacd0e4acbca000142b1812
      o[:settings][:analysis][:char_filter][:ampersand][:mappings] = ['&=> und ']
      o
    end
  end

  belongs_to :body
  has_many :paper_originators, dependent: :destroy
  has_many :originator_people, through: :paper_originators, source: :originator, source_type: 'Person'
  has_many :originator_organizations, through: :paper_originators, source: :originator, source_type: 'Organization'
  has_many :paper_answerers, dependent: :destroy
  has_many :answerer_people, through: :paper_answerers, source: :answerer, source_type: 'Person'
  # has_many :answerer_organizations, through: :paper_answerers, source: :answerer, source_type: 'Organization'
  has_many :answerer_ministries, through: :paper_answerers, source: :answerer, source_type: 'Ministry'

  has_many :paper_relations, foreign_key: :paper_id, dependent: :destroy
  has_many :reverse_paper_relations, class_name: :PaperRelation, foreign_key: :other_paper_id, dependent: :destroy
  has_many :related_papers, through: :paper_relations, source: :other_paper

  scope :search_import, -> { includes(:body, :paper_originators, :originator_people, :originator_organizations) }

  # ATTENTION: use .unscoped if you want to access "raw" papers
  scope :answers, -> { where(is_answer: true) }
  default_scope { where(is_answer: true) }

  def originators
    paper_originators.sort_by { |org| org.originator_type == 'Person' ? 1 : 2 }.map(&:originator)
  end

  def answerers
    paper_answerers.sort_by { |answerer| answerer.answerer_type == 'Person' ? 1 : 2 }.map(&:answerer)
  end

  validates :body, presence: true
  validates :legislative_term, presence: true
  validates :reference, presence: true, uniqueness: { scope: [:body_id, :legislative_term] }

  before_validation :fix_published_at

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

  def should_index?
    is_answer == true && !published_at.nil?
  end

  def search_data
    {
      body: body.state,
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      title: title,
      contents: contents,
      pages: page_count,
      contains_table: contains_table,
      doctype: doctype,
      published_at: published_at,
      created_at: created_at,
      people: originator_people.map(&:name),
      faction: originator_organizations.map(&:slug)
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

  def public_url(force_reload = false)
    Rails.cache.fetch("#{cache_key}/public_url", expires_in: 12.hours, force: force_reload) do
      begin
       AppStorage.bucket.files.head(path).try(:public_url)
      rescue => error
        Rails.logger.warn "Cannot get public_url of paper [#{body.state} #{full_reference}]: #{error}"
        nil
      end
    end
  end

  def download_url
    if body.use_mirror_for_download? && !public_url.nil?
      public_url
    else
      url
    end
  end

  def thumbnail_url(force_reload = false)
    Rails.cache.fetch("#{cache_key}/thumbnail_url", expires_in: 12.hours, force: force_reload) do
      begin
        AppStorage.bucket.files.head(thumbnail_path).try(:public_url)
      rescue => error
        Rails.logger.warn "Cannot get public_url of thumbnail of paper [#{body.state} #{full_reference}]: #{error}"
        nil
      end
    end
  end

  def doctype_human
    case doctype
    when DOCTYPE_MINOR_INTERPELLATION
      'kleine Anfrage'
    when DOCTYPE_MAJOR_INTERPELLATION
      'große Anfrage'
    when DOCTYPE_WRITTEN_INTERPELLATION
      'schriftliche Anfrage'
    else
      ''
    end
  end

  def major?
    doctype == DOCTYPE_MAJOR_INTERPELLATION
  end

  def part_of_series?
    m = series_match
    m.present?
  end

  def series_title
    return nil unless part_of_series?
    series_match.gsub('"', '')
  end

  def description
    desc = []
    desc << "#{doctype_human.titleize} #{full_reference} aus #{ApplicationController.helpers.body_with_prefix(body)}."
    if originator_people.size > 0
      desc << " Eingereicht von #{originator_people.map(&:name).join(', ')}, " +
        "#{originator_organizations.map(&:name).join(', ')}."
    elsif originator_organizations.size > 0
      desc << " Eingereicht von #{originator_organizations.map(&:name).join(', ')}."
    end
    desc << " #{page_count} #{ActionController::Base.helpers.t(:pages, count: page_count)}." if page_count.present?
    desc.join('')
  end

  def freeze
    self.frozen_at = DateTime.now
  end

  def frozen?
    !frozen_at.nil? && frozen_at.to_i > 0
  end

  def originators_parties=(parties)
    parties.each do |party|
      party = normalize(party, 'parties')
      next if party.nil? || party.blank?
      Rails.logger.debug "+ Originator (Party): #{party}" # TODO: refactor
      org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
      originator_organizations << org unless originator_organizations.include? org
    end
  end

  def originators_people=(people)
    people.each do |name|
      name = normalize(name, 'people', body)
      next if name.nil? || name.blank?
      Rails.logger.debug "+ Originator (Person): #{name}" # TODO: refactor
      person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
      originator_people << person unless originator_people.include? person
    end
  end

  def originators=(originators)
    return if originators.nil?
    self.originators_parties = originators[:parties] unless originators[:parties].blank?
    self.originators_people = originators[:people] unless originators[:people].blank?
  end

  def answerers_ministries=(ministries)
    ministries.each do |name|
      ministry = Ministry.where(body: body).where('lower(short_name) = ?', name.mb_chars.downcase.to_s).first
      if ministry.nil?
        name = normalize(name, 'ministries', body)
        next if name.nil?
        ministry = Ministry.where(body: body)
                   .where('lower(name) = ?', name.mb_chars.downcase.to_s)
                   .first_or_create(body: body, name: name)
      end
      Rails.logger.debug "+ Ministry: #{ministry.name}" # TODO: refactor
      answerer_ministries << ministry unless answerer_ministries.include? ministry
    end
  end

  def answerers=(answerers)
    return if answerers.nil?
    self.answerers_ministries = answerers[:ministries] unless answerers[:ministries].blank?
  end

  def problems
    p = []
    p << :wrong_published_at if published_at.nil? || published_at > Date.today
    p << :missing_page_count if page_count.nil?
    p << :missing_contents if contents.nil?
    p << :missing_originator_people if originator_people.size == 0 && !empty_originator_people_allowed?
    p << :missing_originator_organizations if originator_organizations.size == 0
    p << :missing_answerers if paper_answerers.size == 0
    p
  end

  protected

  def series_match
    m = title.strip.match(/(?:\A(.+)\s+\([MDCLXVI\.]+\):|(.+)\s+\([MDCLXVI\.]+\)\z)/)
    if m
      m[1] || m[2]
    end
  end

  def empty_originator_people_allowed?
    doctype == DOCTYPE_MAJOR_INTERPELLATION ||
      (body.state == 'BT' && title.start_with?('Politisch motivierte ')) ||
      (body.state == 'HB')
  end

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    dataset_name = "ka-#{prefix}" + (!body.nil? ? "-#{body.state.downcase}" : '')
    nk_attr = {}
    nk_attr['first_paper_path'] = Rails.application.routes.url_helpers.paper_path(body, legislative_term, self) if self.persisted? && !body.nil?
    Nomenklatura::Dataset.new(dataset_name).lookup(name, attributes: nk_attr)
  end

  def fix_published_at
    return if published_at.nil?
    this_year = Date.today.year
    return unless published_at.year > this_year
    parts = this_year.to_s.split('').sort
    if published_at.year.to_s.split('').sort == parts
      # someone slipped on the keyboard, the years numbers are scrambled
      self.published_at = Date.new(this_year, published_at.month, published_at.day)
    end
  end
end
