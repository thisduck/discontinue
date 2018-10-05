class Api::StreamResource < JSONAPI::Resource
  attributes :name, :state, :started_at, :finished_at, :humanized_time, :build_id

  belongs_to :build
  has_many :boxes

  def humanized_time
    HumanizeSeconds.humanize( (@model.finished_at || Time.now) - @model.started_at )

  end

  def state
    @model.aasm_state
  end
end
