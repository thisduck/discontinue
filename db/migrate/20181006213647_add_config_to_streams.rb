class AddConfigToStreams < ActiveRecord::Migration[5.2]
  def change
    rename_column :streams, :build_commands, :config
    remove_column :streams, :box_count
  end
end
