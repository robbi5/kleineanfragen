class CreateOrganizationsPeople < ActiveRecord::Migration
  def change
    create_table :organizations_people, id: false do |t|
      t.references :organization
      t.references :person
    end

    add_index :organizations_people, [:organization_id, :person_id],
      name: "organizations_people_index",
      unique: true
  end
end
