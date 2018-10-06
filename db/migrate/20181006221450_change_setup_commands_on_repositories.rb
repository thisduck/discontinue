class ChangeSetupCommandsOnRepositories < ActiveRecord::Migration[5.2]
  def change
    rename_column :repositories, :setup_commands, :config
  end
end
