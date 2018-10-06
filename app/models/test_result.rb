class TestResult < ApplicationRecord
  belongs_to :build_id
  belongs_to :stream_id
  belongs_to :box_id
end
