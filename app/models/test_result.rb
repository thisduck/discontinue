class TestResult < ApplicationRecord
  belongs_to :build
  belongs_to :stream
  belongs_to :box

  searchkick
  scope :search_import, -> { includes(:build) }

  def artifacts
    Artifact::Relation.new(self)
  end

  def search_data
    json = as_json
    json["branch"] = build.branch
    json[:build_state] = build.aasm_state
    json
  end

  class Reports
    def self.most_failed(branch: "master", range: 5.days.ago..Time.now)
      results = TestResult.search "*", aggs: {
        test_id: {
          # limit: 10
          # order: {"_term" => "asc"}
        }
      },
      limit: 0,
      where: {
        created_at: {gte: range.first, lte: range.last},
        branch: branch,
        build_state: "passed",
        status: "failed"
      }

      buckets = results.aggregations.dig("test_id", "test_id", "buckets").collect do |bucket|
        {
          count: bucket["doc_count"],
          test: TestResult.search("*", limit: 1, where: {test_id: bucket["key"]}).first
        }
      end
    end
  end
end
