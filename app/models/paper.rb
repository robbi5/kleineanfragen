class Paper < ActiveRecord::Base
  extend FriendlyId
  friendly_id :reference_and_title, use: :scoped, scope: [:body, :legislative_term]

  # enable search
  searchkick  language: "German",
              text_start: [:title],
              highlight: [:title, :contents]

  belongs_to :body
  has_many :paper_originators
  has_many :originator_people, :through => :paper_originators, :source => :originator, :source_type => 'Person'
  has_many :originator_organizations, :through => :paper_originators, :source => :originator, :source_type => 'Organization'

  def originators
    paper_originators.sort_by { |org| org.originator_type == 'Person' ? 1 : 2 }.collect(&:originator)
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
    # or: https://github.com/ankane/searchkick#personalized-results
    as_json only: [:body_id, :legislative_term, :reference, :title, :contents, :published_at]
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

  # helper method to fix non-standard urls in the database
  # apply it with: Paper.find_each(&:normalize_url)
  def normalize_url
    normalized_url = Addressable::URI.parse(self.url).normalize.to_s
    self[:url] = normalized_url
    save!
  end

  def path
    File.join(body.folder_name, legislative_term.to_s, reference.to_s + '.pdf')
  end

  def local_path
    Rails.application.config.paper_storage.join(path)
  end

  def public_url
    FogStorageBucket.files.head(path).try(:public_url)
  end

  def extract_text
    tempdir = Dir.mktmpdir

    Docsplit.extract_text(local_path, :ocr => false, :output => tempdir)
    resultfile = "#{tempdir}/#{reference.to_s}.txt"
    return false unless File.exists?(resultfile)

    File.read resultfile
  ensure
    FileUtils.remove_entry_secure tempdir if File.exists?(tempdir)
  end

  def extract_page_count
    Docsplit.extract_length local_path
  end
end
