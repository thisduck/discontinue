require 'humanize_seconds'
class Api::BuildResource < JSONAPI::Resource
  include BuildResourceConcern

  attributes :build_request_id

  has_one :build_request

  has_many :streams
  has_one :build_summary, foreign_key: :id, foreign_key_on: :related
  has_one :build_timing, foreign_key: :id, foreign_key_on: :related
  has_one :profile_summary, foreign_key: :id, foreign_key_on: :related

  def self.records(options = {})
    context = options[:context]
    context[:current_user].builds
  end
end
