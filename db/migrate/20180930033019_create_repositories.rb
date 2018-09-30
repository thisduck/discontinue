class CreateRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :github_id
      t.string :github_url
      t.text :setup_commands

      t.timestamps
    end
  end
end
