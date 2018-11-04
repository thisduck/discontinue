class BuildRequest < ApplicationRecord
  include BuildSearchData

  belongs_to :repository
  has_many :builds
  has_one :last_build, -> { order(created_at: :desc) }, class_name: 'Build'

  validates_presence_of :branch, :repository, :aasm_state

  include AASM

  aasm do
    state :created, initial: true
    state :queued, before_enter: :queue_request

    event :queue do
      transitions from: :created, to: :queued
    end

    event :requeue do
      transitions from: :queued, to: :queued
    end
  end

  def self.add_request(options = {})
    request = BuildRequest.create! options
    request.queue! unless request.ignore_build?
  end

  def ignore_build?
    return true if skip_ci_message?

    # TODO: add ignore branches feature
    filter_branches = repository.filter_branches
    return true if filter_branches['exclude'].any? {|filter| File.fnmatch(filter, branch) }
    return true if filter_branches['include'].none? {|filter| File.fnmatch(filter, branch) }

    false
  end

  private
  def queue_request
    Build.queue(
      branch: branch,
      sha: sha,
      hook_hash: hook_hash,
      repository: repository,
      build_request: self
    )
  end

  def skip_ci_message?
    head_commit = hook_hash['head_commit']
    return true if head_commit.blank?

    case head_commit['message']
    when /\[skip ci\]/
      true
    when /\[ci skip\]/
      true
    else
      false
    end
  end
end
