module BuildSearchData
  extend ActiveSupport::Concern

  included do
    searchkick word_start: [:all]
    scope :search_import, -> { includes(:repository) }
  end

  def search_data
    json = as_json
    json[:all] = [
      branch,
      branch.split("_"),
      branch.split("-"),
      sha,
      hook_hash.dig("pusher", "name"),
      hook_hash.dig("pusher", "email"),
      hook_hash.dig("head_commit", "author", "name"),
      hook_hash.dig("head_commit", "author", "email"),
      hook_hash.dig("head_commit", "author", "username"),
      # hook_hash.dig("head_commit", "message"),
      repository.name
    ].compact.join(" ")
    json[:account_id] = repository.account_id
    json
  end
end
