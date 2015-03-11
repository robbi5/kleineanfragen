class Subscription < ActiveRecord::Base
  enum subtype: [:body, :search] # FIXME: all?

  validates :email, presence: true, email: true
  validates :subtype, presence: true
  validates :query, presence: true
  validate :not_already_subscribed

  def to_param
    self.class.hashids.encode(id)
  end

  def self.find_by_hash(hash)
    id = hashids.decode(hash).first
    find(id)
  end

  def self.hashids
    # FIXME: salt per installation
    Hashids.new('Subscription', 5)
  end

  private

  def not_already_subscribed
    other = self.class.where(email: email, subtype: subtype, query: query, active: true).where.not(id: id)
    if other.exists?
      errors.add(:base, 'existiert bereits')
    end
  end
end
