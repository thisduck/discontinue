class CreateStreams < ActiveRecord::Migration[5.2]
  def change
    create_table :streams do |t|
      t.references :build, foreign_key: true
      t.string :build_stream_id
      t.string :name
      t.string :aasm_state
      t.text :build_commands
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end
  end
end
