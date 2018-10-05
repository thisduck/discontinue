require 'humanize_seconds'
class Api::BoxResource < JSONAPI::Resource
  attributes :state, :started_at, :finished_at, :stream_id, :humanized_time

  belongs_to :stream

  def humanized_time
    HumanizeSeconds.humanize( (@model.finished_at || Time.now) - @model.started_at )
  end

  def state
    @model.aasm_state
  end
end
