module BuildResourceConcern
  extend ActiveSupport::Concern

  included do
    attributes :branch, :created_at, :events, :hook_hash, :repository_id, :sha, :state
    has_one :repository
    paginator :paged

    filter :query, apply: ->(records, value, options) {

      params = {
        match: :word_start,
        fields: ["branch^10", "all"],
        where: {
          account_id: options[:context][:current_user].accounts.pluck(:id)
        }
      }

      if options[:sort_criteria]
        params[:order] = {}
        options[:sort_criteria].each do |sort|
          params[:order][sort[:field]] = sort[:direction]
        end
      end

      if options[:paginator]
        params[:page] = options[:paginator].number
        params[:per_page] = options[:paginator].size
      end

      results = records.search(value[0], params)
      options[:context][:elastic] = {
        total: results.response.dig("hits", "total")
      }

      results
    }
  end

  def model_type

  end

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name) - [:pass_build, :fail_build]
  end

  class_methods do
    def sort_records(records, order_options, context = {})
      if records.is_a? Searchkick::Results
        records
      else
        super
      end
    end

    def apply_pagination(records, paginator, order_options)
      if records.is_a? Searchkick::Results
        records
      else
        super
      end
    end

    def find_count(filters, options = {})
      total = options[:context].dig(:elastic, :total)
      return total if total

      super
    end
  end
end
