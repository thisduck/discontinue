class TestResult < ApplicationRecord
  belongs_to :build
  belongs_to :stream
  belongs_to :box

  def artifacts
    Artifact::Relation.new(self)
  end
end
