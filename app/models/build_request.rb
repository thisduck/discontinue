class BuildRequest < ApplicationRecord
  belongs_to :repository

  validates_presence_of :branch, :sha, :repository, :aasm_state

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
    return true
    return true if skip_ci_message?

    # TODO: add ignore branches feature
    return true if branch.start_with?("finbot_")

    false
  end

  private
  def queue_request

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
