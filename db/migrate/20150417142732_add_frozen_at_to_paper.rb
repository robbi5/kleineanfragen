# Sometimes the scrapers/extractors produce weird data, because
# the original source had corrupt data. In those cases we can
# "freeze" the paper and correct the data manually. The freezing
# allows to skip the paper in the jobs (see PaperJob) for the case
# the paper is accessed again.
class AddFrozenAtToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :frozen_at, :datetime
  end
end
