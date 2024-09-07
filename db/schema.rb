# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_09_07_070628) do
  create_table "albums", force: :cascade do |t|
    t.string "artist_name"
    t.string "album_name"
    t.string "itunes_album_id"
    t.string "artwork_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "instruments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "matches", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "other_user_id", null: false
    t.integer "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["other_user_id"], name: "index_matches_on_other_user_id"
    t.index ["user_id", "other_user_id"], name: "index_matches_on_user_id_and_other_user_id", unique: true
    t.index ["user_id"], name: "index_matches_on_user_id"
  end

  create_table "user_albums", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "album_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_user_albums_on_album_id"
    t.index ["user_id"], name: "index_user_albums_on_user_id"
  end

  create_table "user_areas", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_user_areas_on_area_id"
    t.index ["user_id"], name: "index_user_areas_on_user_id"
  end

  create_table "user_instruments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "instrument_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument_id"], name: "index_user_instruments_on_instrument_id"
    t.index ["user_id"], name: "index_user_instruments_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "birthdate"
    t.string "gender"
    t.string "purpose", default: "hobby"
    t.text "introduction"
    t.string "profile_image"
    t.string "x_link"
    t.string "instagram_link"
    t.string "youtube_link"
    t.string "custom_link"
    t.text "like_music"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "matches", "users"
  add_foreign_key "matches", "users", column: "other_user_id"
  add_foreign_key "user_albums", "albums"
  add_foreign_key "user_albums", "users"
  add_foreign_key "user_areas", "areas"
  add_foreign_key "user_areas", "users"
  add_foreign_key "user_instruments", "instruments"
  add_foreign_key "user_instruments", "users"
end
