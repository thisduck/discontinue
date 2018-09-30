class AddAttachmentOutputToBoxes < ActiveRecord::Migration[5.2]
  def self.up
    change_table :boxes do |t|
      t.attachment :output
    end
  end

  def self.down
    remove_attachment :boxes, :output
  end
end
