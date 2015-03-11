class Subscription < ActiveRecord::Base
  enum subtype: [:body, :search] # FIXME: all?

  validates :email, presence: true, email: true
  validates :subtype, presence: true
  validates :query, presence: true
  # FIXME: validate subtype
  validate :body_query_is_existing
  validate :not_already_subscribed

  def to_param
    self.class.hashids.encode(id)
  end

  def self.find_by_hash(hash)
    id = hashids.decode(hash).first
    find(id)
  end

  def self.hashids
    Hashids.new('Subscription' + Rails.application.secrets.subscription_salt, 5)
  end

  def subject
    case subtype
    when 'body'
      Body.find_by_state(query).try(:name) || 'kleine Anfragen'
    when 'search'
      'Suche'
    else
      'kleine Anfragen'
    end
  end

  private

  def not_already_subscribed
    other = self.class.where(email: email, subtype: subtype, query: query, active: true).where.not(id: id)
    if other.exists?
      errors.add(:base, 'existiert bereits')
    end
  end

  def body_query_is_existing
    if subtype == :body && Body.find_by_state(query).nil?
      errors.add(:query, :invalid)
    end
  end
end