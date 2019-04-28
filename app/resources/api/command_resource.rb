class Api::CommandResource < JSONAPI::Resource
  attributes :command, :lines, :started_at, :box_id,
    :finished_at, :state, :humanized_time, :return_code

  key_type :uuid

  belongs_to :box
end
