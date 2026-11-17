module BuildResourceConcern
  extend ActiveSupport::Concern

  included do
    attributes :branch, :created_at, :events, :hook_hash, :repository_id, :sha, :state
    has_one :repository, use_related_resource_records_for_joins: false
    paginator :paged

    filter :query, apply: ->(records, value, options) {

      results = records.klass.search(value.first,
        match: :word_start,
        fields: ["branch^10", "all"],
        where: { account_id: options[:context][:current_user].accounts.pluck(:id) },
        load: false,
        limit: 10_000
      )
      # ponytail: cap at the search engine's result window; use cursor pagination for larger collections.
      records.where(id: results.hits.map { |hit| hit.fetch('_id') })
    }
  end


  def state
    @model.aasm_state
  end

  def events
    return [] if Rails.configuration.x.demo_mode

    @model.aasm.events(permitted: true).map(&:name) - [:pass_build, :fail_build]
  end

end
