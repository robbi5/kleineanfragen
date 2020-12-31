# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20201231234052) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bodies", id: :serial, force: :cascade do |t|
    t.text "name"
    t.string "state", limit: 2
    t.text "website"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.boolean "use_mirror_for_download", default: false
    t.string "wikidataq"
    t.text "site_message"
    t.index ["name"], name: "index_bodies_on_name", unique: true
    t.index ["slug"], name: "index_bodies_on_slug", unique: true
    t.index ["state"], name: "index_bodies_on_state", unique: true
  end

  create_table "email_blacklists", id: :serial, force: :cascade do |t|
    t.string "email"
    t.integer "reason"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "legislative_terms", id: :serial, force: :cascade do |t|
    t.integer "body_id"
    t.integer "term"
    t.date "starts_at"
    t.date "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wikidataq"
    t.index ["body_id", "term"], name: "index_legislative_terms_on_body_id_and_term", unique: true
    t.index ["body_id"], name: "index_legislative_terms_on_body_id"
  end

  create_table "ministries", id: :serial, force: :cascade do |t|
    t.integer "body_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name"
    t.string "slug"
    t.datetime "deleted_at"
    t.index ["body_id", "name"], name: "index_ministries_on_body_id_and_name", unique: true
    t.index ["body_id", "slug"], name: "index_ministries_on_body_id_and_slug", unique: true
    t.index ["body_id"], name: "index_ministries_on_body_id"
    t.index ["deleted_at"], name: "index_ministries_on_deleted_at"
  end

  create_table "opt_ins", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["name"], name: "index_organizations_on_name", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "organizations_people", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "person_id"
    t.index ["organization_id", "person_id"], name: "organizations_people_index", unique: true
  end

  create_table "paper_answerers", id: :serial, force: :cascade do |t|
    t.integer "paper_id"
    t.string "answerer_type"
    t.integer "answerer_id"
    t.index ["answerer_type", "answerer_id"], name: "index_paper_answerers_on_answerer_type_and_answerer_id"
    t.index ["paper_id"], name: "index_paper_answerers_on_paper_id"
  end

  create_table "paper_originators", id: :serial, force: :cascade do |t|
    t.integer "paper_id"
    t.string "originator_type"
    t.integer "originator_id"
    t.index ["originator_type", "originator_id"], name: "index_paper_originators_on_originator_type_and_originator_id"
    t.index ["paper_id"], name: "index_paper_originators_on_paper_id"
  end

  create_table "paper_redirects", id: :serial, force: :cascade do |t|
    t.integer "body_id", null: false
    t.integer "legislative_term"
    t.text "reference"
    t.integer "paper_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_id"], name: "index_paper_redirects_on_body_id"
    t.index ["paper_id"], name: "index_paper_redirects_on_paper_id"
  end

  create_table "paper_relations", id: :serial, force: :cascade do |t|
    t.integer "paper_id", null: false
    t.integer "other_paper_id", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["other_paper_id"], name: "index_paper_relations_on_other_paper_id"
    t.index ["paper_id", "other_paper_id", "reason"], name: "index_paper_relations_on_p_and_other_p_and_reason", unique: true
    t.index ["paper_id"], name: "index_paper_relations_on_paper_id"
  end

  create_table "papers", id: :serial, force: :cascade do |t|
    t.integer "body_id"
    t.integer "legislative_term"
    t.text "reference"
    t.text "title"
    t.text "contents"
    t.integer "page_count"
    t.text "url"
    t.date "published_at"
    t.datetime "downloaded_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.boolean "contains_table"
    t.datetime "pdf_last_modified"
    t.string "doctype"
    t.boolean "is_answer", default: false, null: false
    t.datetime "frozen_at"
    t.string "source_url"
    t.datetime "deleted_at"
    t.boolean "contains_classified_information"
    t.index ["body_id", "legislative_term", "reference"], name: "index_papers_on_body_id_and_legislative_term_and_reference", unique: true
    t.index ["body_id", "legislative_term", "slug"], name: "index_papers_on_body_id_and_legislative_term_and_slug", unique: true
    t.index ["body_id"], name: "index_papers_on_body_id"
    t.index ["deleted_at"], name: "index_papers_on_deleted_at"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "party"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.datetime "deleted_at"
    t.string "wikidataq"
    t.index ["deleted_at"], name: "index_people_on_deleted_at"
    t.index ["name"], name: "index_people_on_name", unique: true
    t.index ["slug"], name: "index_people_on_slug", unique: true
  end

  create_table "scraper_results", id: :serial, force: :cascade do |t|
    t.integer "body_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "success"
    t.string "message"
    t.integer "new_papers"
    t.integer "old_papers"
    t.string "scraper_class"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.string "email"
    t.integer "subtype"
    t.string "query"
    t.boolean "active"
    t.datetime "last_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "legislative_terms", "bodies"
  add_foreign_key "ministries", "bodies"
  add_foreign_key "paper_answerers", "papers"
  add_foreign_key "paper_redirects", "bodies"
  add_foreign_key "paper_redirects", "papers"
  add_foreign_key "paper_relations", "papers"
  add_foreign_key "paper_relations", "papers", column: "other_paper_id"
end
