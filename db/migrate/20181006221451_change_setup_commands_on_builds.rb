class ChangeSetupCommandsOnBuilds < ActiveRecord::Migration[5.2]
  def change
    rename_column :builds, :setup_commands, :config
  end
end
