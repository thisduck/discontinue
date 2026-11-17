# JSONAPI Resources 0.10 hard-codes PostgreSQL-style identifier quotes.
JSONAPI::ActiveRelationResource.singleton_class.prepend(Module.new do
  def quote(field)
    ActiveRecord::Base.connection_pool.with_connection { |connection| connection.quote_column_name(field) }
  end
end)

JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged

  config.default_page_size = 10
  config.maximum_page_size = 50
end
