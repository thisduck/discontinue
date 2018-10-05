class Api::CommandResource < JSONAPI::Resource
  attributes :command, :lines, :started_at, :box_id,
    :finished_at, :state, :humanized_time

  key_type :uuid

  belongs_to :box
end
