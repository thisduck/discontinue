class RestoreBuildDurations < ActiveRecord::Migration[7.2]
  def up
    # These columns were captured in schema.rb but are absent from the original migrations.
    add_column :builds, :duration, :bigint, if_not_exists: true
    add_column :streams, :duration, :bigint, if_not_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'These columns may predate this migration'
  end
end