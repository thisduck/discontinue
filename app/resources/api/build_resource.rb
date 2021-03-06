require 'humanize_seconds'
class Api::BuildResource < JSONAPI::Resource
  include BuildResourceConcern

  attributes :build_request_id

  belongs_to :build_request

  has_many :streams
  has_one :build_summary
  has_one :build_timing
  has_one :profile_summary

  def self.records(options = {})
    context = options[:context]
    context[:current_user].builds
  end
end
