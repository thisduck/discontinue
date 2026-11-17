class Api::CommandResource < JSONAPI::Resource
  attributes :command, :lines, :started_at, :box_id,
    :finished_at, :state, :humanized_time

  key_type :uuid

  has_one :box
end
