class Body < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :papers, -> { answers }
  has_many :ministries
  has_many :organizations, -> { distinct }, through: :papers, source: :originator_organizations
  has_many :scraper_results
  has_many :legislative_terms, -> { order(term: :desc) }
  has_many :people, -> { distinct }, through: :papers, source: :originator_people

  validates :name, uniqueness: true
  validates :state, uniqueness: true

  def key
    state.downcase
  end

  alias_method :folder_name, :key

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  def twitter_handle
    "anfragen_#{state.downcase}"
  end

  def scraper
    case state
    when 'BB' then BrandenburgLandtagScraper
    when 'BE' then BerlinAghScraper
    when 'BT' then BundestagScraper
    when 'BW' then BadenWuerttembergLandtagScraper
    when 'BY' then BayernLandtagScraper
    when 'HB' then BremenBuergerschaftScraper
    when 'HE' then HessenScraper
    when 'HH' then HamburgBuergerschaftScraper
    when 'MV' then MeckPommLandtagScraper
    when 'NI' then NiedersachsenLandtagScraper
    when 'NW' then NordrheinWestfalenLandtagScraper
    when 'RP' then RheinlandPfalzLandtagScraper
    when 'SH' then SchleswigHolsteinLandtagScraper
    when 'SL' then SaarlandScraper
    when 'SN' then SachsenScraper
    when 'ST' then SachsenAnhaltLandtagScraper
    when 'TH' then ThueringenLandtagScraper
    end
  end

  def create_nomenklatura_datasets
    return false if Rails.configuration.x.nomenklatura_api_key.blank?
    datasets = []
    datasets << Nomenklatura::Dataset.create("ka-ministries-#{state.downcase}", "kleineAnfragen Ministerien #{state}")
    datasets << Nomenklatura::Dataset.create("ka-people-#{state.downcase}", "kleineAnfragen Personen #{state}")
    datasets
  end
end
