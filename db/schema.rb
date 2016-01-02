# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160102120618) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bodies", force: :cascade do |t|
    t.text     "name"
    t.string   "state",                   limit: 2
    t.text     "website"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.boolean  "use_mirror_for_download",           default: false
  end

  add_index "bodies", ["name"], name: "index_bodies_on_name", unique: true, using: :btree
  add_index "bodies", ["slug"], name: "index_bodies_on_slug", unique: true, using: :btree
  add_index "bodies", ["state"], name: "index_bodies_on_state", unique: true, using: :btree

  create_table "email_blacklists", force: :cascade do |t|
    t.string   "email"
    t.integer  "reason"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "ministries", force: :cascade do |t|
    t.integer  "body_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "short_name"
    t.string   "slug"
  end

  add_index "ministries", ["body_id", "name"], name: "index_ministries_on_body_id_and_name", unique: true, using: :btree
  add_index "ministries", ["body_id", "slug"], name: "index_ministries_on_body_id_and_slug", unique: true, using: :btree
  add_index "ministries", ["body_id"], name: "index_ministries_on_body_id", using: :btree

  create_table "opt_ins", force: :cascade do |t|
    t.string   "email"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.string   "confirmed_ip"
    t.string   "created_ip"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "organizations", ["name"], name: "index_organizations_on_name", unique: true, using: :btree
  add_index "organizations", ["slug"], name: "index_organizations_on_slug", unique: true, using: :btree

  create_table "organizations_people", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "person_id"
  end

  add_index "organizations_people", ["organization_id", "person_id"], name: "organizations_people_index", unique: true, using: :btree

  create_table "paper_answerers", force: :cascade do |t|
    t.integer "paper_id"
    t.integer "answerer_id"
    t.string  "answerer_type"
  end

  add_index "paper_answerers", ["answerer_type", "answerer_id"], name: "index_paper_answerers_on_answerer_type_and_answerer_id", using: :btree
  add_index "paper_answerers", ["paper_id"], name: "index_paper_answerers_on_paper_id", using: :btree

  create_table "paper_originators", force: :cascade do |t|
    t.integer "paper_id"
    t.integer "originator_id"
    t.string  "originator_type"
  end

  add_index "paper_originators", ["originator_type", "originator_id"], name: "index_paper_originators_on_originator_type_and_originator_id", using: :btree
  add_index "paper_originators", ["paper_id"], name: "index_paper_originators_on_paper_id", using: :btree

  create_table "papers", force: :cascade do |t|
    t.integer  "body_id"
    t.integer  "legislative_term"
    t.text     "reference"
    t.text     "title"
    t.text     "contents"
    t.integer  "page_count"
    t.text     "url"
    t.date     "published_at"
    t.datetime "downloaded_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.boolean  "contains_table"
    t.datetime "pdf_last_modified"
    t.string   "doctype"
    t.boolean  "is_answer"
    t.datetime "frozen_at"
  end

  add_index "papers", ["body_id", "legislative_term", "reference"], name: "index_papers_on_body_id_and_legislative_term_and_reference", unique: true, using: :btree
  add_index "papers", ["body_id", "legislative_term", "slug"], name: "index_papers_on_body_id_and_legislative_term_and_slug", unique: true, using: :btree
  add_index "papers", ["body_id"], name: "index_papers_on_body_id", using: :btree

  create_table "people", force: :cascade do |t|
    t.text     "name"
    t.text     "party"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "people", ["name"], name: "index_people_on_name", unique: true, using: :btree

  create_table "scraper_results", force: :cascade do |t|
    t.integer  "body_id"
    t.datetime "started_at"
    t.datetime "stopped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean  "success"
    t.string   "message"
    t.integer  "new_papers"
    t.integer  "old_papers"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "email"
    t.integer  "subtype"
    t.string   "query"
    t.boolean  "active"
    t.datetime "last_sent_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_foreign_key "ministries", "bodies"
  add_foreign_key "paper_answerers", "papers"
end
