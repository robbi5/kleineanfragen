class EmailBlacklist < ApplicationRecord
  enum reason: [:report, :support]

  def email=(val)
    write_attribute(:email, val.downcase)
  end

  def self.active_and_email(val)
    where('deleted_at IS NULL').where(email: val.downcase)
  end
end
