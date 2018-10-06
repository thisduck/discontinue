class CreateTestResults < ActiveRecord::Migration[5.2]
  def change
    create_table :test_results do |t|
      t.string :test_id
      t.string :test_type
      t.string :description
      t.string :status
      t.string :file_path
      t.string :line_number
      t.references :build, foreign_key: true
      t.references :stream, foreign_key: true
      t.references :box, foreign_key: true
      t.json :exception
      t.integer :duration

      t.timestamps
    end
  end
end
