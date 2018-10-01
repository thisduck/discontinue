class CreateBoxes < ActiveRecord::Migration[5.2]
  def change
    create_table :boxes do |t|
      t.references :stream, foreign_key: true
      t.string :instance_id
      t.string :instance_type
      t.string :box_number
      t.string :aasm_state
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end
  end
end
