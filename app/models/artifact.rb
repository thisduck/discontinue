class Artifact
  include ActiveModel::Model

  attr_reader :id, :key, :filename, :extension, :size, :presigned_url, :box_id

  def initialize(args, box)
    @key = args[:key]
    @filename = args[:filename]
    @extension = args[:extension]
    @size = args[:size]
    @presigned_url = args[:presigned_url]
    @id ="artifact-#{box.id}-#{args[:key]}"
    @box_id = box.id
  end

  def self.all
    new
  end

  class Relation
    attr_reader :box

    def initialize(box)
      @box = box
    end

    def order(*args)
      box.artifact_listing.collect do |artifact, index|
        key = artifact.key
        Artifact.new({
          key: key,
          filename: File.basename(key),
          extension: File.extname(key),
          size: number_helper.number_to_human_size(artifact.data.size),
          presigned_url: artifact.presigned_url('get'),
        }, box)
      end
    end

    private
    def number_helper
      @number_helper ||= Class.new.tap do |helper|
        helper.extend ActionView::Helpers::NumberHelper
      end
    end
  end
end
