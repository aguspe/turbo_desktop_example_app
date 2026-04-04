ActiveRecord::Schema[7.0].define(version: 1) do
  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "priority", default: "medium"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
