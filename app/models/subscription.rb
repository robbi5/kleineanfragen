class Subscription < ActiveRecord::Base
  enum subtype: [:body, :search] # FIXME: all?

  validates :email, presence: true, email: true
  validates :subtype, presence: true
  validates :query, presence: true

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
end
