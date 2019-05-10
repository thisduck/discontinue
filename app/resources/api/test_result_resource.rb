class Api::TestResultResource < JSONAPI::Resource
  attributes :build_id, :stream_id, :test_id, :test_type,
    :description, :status, :file_path, :line_number, :exception, :duration,
    :created_at, :box_id

  belongs_to :stream, always_include_linkage_data: true
  belongs_to :box, always_include_linkage_data: true
  belongs_to :build, always_include_linkage_data: true
  has_many   :artifacts
  paginator :paged
  filter :status
  filter :stream_id
  filter :test_id
  filter :box_id
  filter :branch

  def duration
    @model.duration / 1_000_000_000.0
  end
end
