require 'humanize_seconds'
class Api::BoxResource < JSONAPI::Resource
  attributes :state, :started_at, :finished_at, :stream_id, :humanized_time,
    :artifact_listing, :box_number

  belongs_to :stream
  has_many :commands

  def humanized_time
    HumanizeSeconds.humanize( (@model.finished_at || Time.now) - @model.started_at )
  end

  def state
    @model.aasm_state
  end

  def artifact_listing
    build_id = stream.build.id
    stream_id = stream.id

    @model.artifact_listing.map do |artifact|
      {
        key: artifact.key,
        build_id: build_id,
        stream_id: stream_id,
        box_id: id
      }
    end
  end
end
