class Api::TestResultResource < JSONAPI::Resource
  attributes :build_id, :stream_id, :test_id, :test_type,
    :description, :status, :file_path, :line_number, :exception, :duration,
    :created_at

  belongs_to :stream
  paginator :paged
  filter :status
  filter :stream_id
end
