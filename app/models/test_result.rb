class TestResult < ApplicationRecord
  belongs_to :build
  belongs_to :stream
  belongs_to :box
end
