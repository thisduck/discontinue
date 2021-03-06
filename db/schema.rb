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

ActiveRecord::Schema.define(version: 2018_10_06_221451) do

  create_table "accounts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "integration_type"
    t.string "integration_id"
    t.string "integration_account_type"
    t.string "integration_installation_id"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "accounts_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.index ["account_id", "user_id"], name: "index_accounts_users_on_account_id_and_user_id"
    t.index ["account_id"], name: "index_accounts_users_on_account_id"
    t.index ["user_id"], name: "index_accounts_users_on_user_id"
  end

  create_table "boxes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "stream_id"
    t.string "instance_id"
    t.string "instance_type"
    t.string "box_number"
    t.string "aasm_state"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "output_file_name"
    t.string "output_content_type"
    t.bigint "output_file_size"
    t.datetime "output_updated_at"
    t.index ["stream_id"], name: "index_boxes_on_stream_id"
  end

  create_table "build_requests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "branch"
    t.string "sha"
    t.json "hook_hash"
    t.bigint "repository_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_build_requests_on_repository_id"
  end

  create_table "builds", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "branch"
    t.string "sha"
    t.json "hook_hash"
    t.bigint "build_request_id"
    t.bigint "repository_id"
    t.string "aasm_state"
    t.text "config"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "error_message"
    t.bigint "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["build_request_id"], name: "index_builds_on_build_request_id"
    t.index ["repository_id"], name: "index_builds_on_repository_id"
    t.index ["branch"], name: "index_builds_on_branch"
  end

  create_table "delayed_jobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "repositories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "full_name"
    t.string "integration_type"
    t.string "integration_id"
    t.string "url"
    t.boolean "private_repo"
    t.boolean "active"
    t.text "config"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "stream_configs"
    t.index ["account_id"], name: "index_repositories_on_account_id"
  end

  create_table "streams", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "build_id"
    t.string "build_stream_id"
    t.string "name"
    t.string "aasm_state"
    t.text "config"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "error_message"
    t.bigint "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["build_id"], name: "index_streams_on_build_id"
  end

  create_table "test_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "test_id"
    t.string "test_type"
    t.text "description"
    t.string "status"
    t.string "file_path"
    t.string "line_number"
    t.bigint "build_id"
    t.bigint "stream_id"
    t.bigint "box_id"
    t.json "exception"
    t.bigint "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["box_id"], name: "index_test_results_on_box_id"
    t.index ["build_id"], name: "index_test_results_on_build_id"
    t.index ["stream_id"], name: "index_test_results_on_stream_id"
    t.index ["test_id"], name: "index_test_results_on_test_id"
    t.index ["created_at"], name: "index_test_results_on_created_at"
    t.index ["status"], name: "index_test_results_on_status"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email"
    t.string "integration_type"
    t.string "integration_id"
    t.string "integration_login"
    t.string "avatar_url"
    t.string "access_token"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "boxes", "streams"
  add_foreign_key "build_requests", "repositories"
  add_foreign_key "builds", "build_requests"
  add_foreign_key "builds", "repositories"
  add_foreign_key "repositories", "accounts"
  add_foreign_key "streams", "builds"
  add_foreign_key "test_results", "boxes"
  add_foreign_key "test_results", "builds"
  add_foreign_key "test_results", "streams"
end
