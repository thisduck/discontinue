require 'humanize_seconds'
class Api::BuildResource < JSONAPI::Resource
  attributes :branch, :sha, :build_request_id, :state,
    :hook_hash, :events, :repository_id, :created_at

  belongs_to :build_request
  belongs_to :repository

  has_many :streams
  has_one :build_summary
  has_one :build_timing
  has_one :profile_summary

  paginator :paged
  filter :branch, apply: ->(records, value, _options) {
    records.where("branch like ?", "%#{value[0]}%")
  }

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name)
  end

end
