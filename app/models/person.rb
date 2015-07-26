class Person < ActiveRecord::Base
  has_and_belongs_to_many :organizations

  has_many :paper_originators, as: :originator
  has_many :papers, -> { answers }, through: :paper_originators

  validates :name, uniqueness: true

  def bodies
    Body.find papers.pluck(:body_id).uniq
  end

  def nomenklatura_sync!
    fail 'This person appears in multiple bodies' if bodies.size > 1
    body = bodies.first

    dataset = Nomenklatura::Dataset.new("ka-people-#{body.state.downcase}")
    entity = dataset.entity_by_name(name).dereference
    if entity.invalid?
      # invalid: remove self
      papers.clear
      destroy
    elsif entity.name != name
      new_name = entity.name
      if self.class.exists?(name: new_name)
        # new name and person exists? reassign papers, remove self
        other = self.class.find_by_name(new_name)
        other.papers << papers
        other.save!
        papers.clear
        destroy
      else
        # new name and person doesn't exist? rename self
        self.name = new_name
        save!
      end
    else
      self
    end
  end
end
