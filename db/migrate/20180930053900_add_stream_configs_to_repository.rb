class AddStreamConfigsToRepository < ActiveRecord::Migration[5.2]
  def change
    add_column :repositories, :stream_configs, :json
  end
end
