class Body < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :papers, -> { answers }
  has_many :ministries

  validates :name, uniqueness: true
  validates :state, uniqueness: true

  def folder_name
    state.downcase
  end

  def should_generate_new_friendly_id?
    name_changed? || super
  end

  def scraper
    case state
    when 'BY' then BayernLandtagScraper
    when 'BE' then BerlinAghScraper
    when 'BB' then BrandenburgLandtagScraper
    when 'BT' then BundestagScraper
    when 'RP' then RheinlandPfalzLandtagScraper
    when 'MV' then MeckPommLandtagScraper
    when 'NS' then NiedersachsenLandtagScraper
    when 'HH' then HamburgBuergerschaftScraper
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
