class Subscription < ActiveRecord::Base
  enum type: [:body, :search] # FIXME: all?

  validates :email, presence: true, email: true
  validates :type, presence: true
  validates :query, presence: true

  def to_param
    hashids.encrypt(id)
  end

  def self.find_by_hash(hash)
    id = hashids.decrypt(hash).first
    find(id.to_i) # FIXME: test, if i
  end

  def self.hashids
    # FIXME: salt per installation
    Hashids.new('Subscription', 5)
  end
end
