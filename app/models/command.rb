class Command
  include ActiveModel::Model

  attr_reader :id, :command, :lines, :started_at, :box_id, :finished_at, :state, :humanized_time

  def initialize(args, box)
    @command = args[:command]
    @lines = args[:lines]
    @started_at = args[:started_at]
    @finished_at = args[:finished_at]
    @state = args[:state]
    @humanized_time = args[:humanized_time]
    @id = args[:id]
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
      box.output_content_split.collect do |output, index|
        Command.new(output, box)
      end
    end

  end
end
