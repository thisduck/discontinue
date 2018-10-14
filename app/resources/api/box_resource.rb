require 'humanize_seconds'
class Api::BoxResource < JSONAPI::Resource
  include ActionView::Helpers::NumberHelper

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
    @model.artifact_listing.map do |artifact|
      key = artifact.key
      {
        key: key,
        filename: File.basename(key),
        extension: File.extname(key),
        size: number_to_human_size(artifact.data.size),
        presigned_url: artifact.presigned_url('get'),
      }
    end
  end
end
