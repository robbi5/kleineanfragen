module NkSyncable
  extend ActiveSupport::Concern

  def nomenklatura_dataset
    if has_attribute?(:body) || has_attribute?(:body_id)
      state = body.state
    elsif self.class.method_defined? :bodies
      fail 'This entity appears in multiple bodies' if bodies.size > 1
      state = bodies.first.state
    else
      fail 'No body attribute found'
    end

    model_name = self.class.name.underscore.pluralize

    "ka-#{model_name}-#{state.downcase}"
  end

  def nomenklatura_sync!(case_insensitive: true)
    dataset = Nomenklatura::Dataset.new(nomenklatura_dataset)
    entity = dataset.entity_by_name(name).dereference
    if entity.invalid?
      # invalid: remove self
      papers.clear
      return destroy
    end

    same = entity.name == name

    if !same
      new_name = entity.name
      other = nil
      if self.class.exists?(name: new_name)
        # new name and object exists?
        other = self.class.find_by_name(new_name)
      elsif case_insensitive && self.class.exists?(["lower(name) = ?", new_name.downcase])
        # same, but for lower
        other = self.class.where("lower(name) = ?", new_name.downcase).first
      end

      # new name and object doesn't exist? rename self
      if other.nil?
        self.name = new_name
        return save!
      end

      if other.id == id
        return self
      end

      # reassign papers, remove self
      papers.each do |paper|
        other.papers << paper unless other.papers.include?(paper)
      end
      other.save!
      papers.clear
      return destroy
    end

    self
  end
end