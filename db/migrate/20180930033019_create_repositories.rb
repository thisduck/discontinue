class CreateRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :full_name
      t.string :integration_type
      t.string :integration_id
      t.string :url
      t.boolean :private_repo
      t.boolean :active
      t.text :setup_commands
      t.references :account, foreign_key: true

      t.timestamps
    end
  end
end
