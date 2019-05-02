JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged

  config.default_page_size = 10
  config.maximum_page_size = 50

  # config.always_include_to_one_linkage_data = true
end
