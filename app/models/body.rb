class Body < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :papers

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
    else nil
    end
  end
end
