class CreateBuildRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :build_requests do |t|
      t.string :branch
      t.string :sha
      t.json :hook_hash
      t.references :repository, foreign_key: true
      t.string :aasm_state

      t.timestamps
    end
  end
end
