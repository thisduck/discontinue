class CreateBuilds < ActiveRecord::Migration[5.2]
  def change
    create_table :builds do |t|
      t.string :branch
      t.string :sha
      t.json :hook_hash
      t.references :build_request, foreign_key: true
      t.references :repository, foreign_key: true
      t.string :aasm_state
      t.text :setup_commands
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end
  end
end
