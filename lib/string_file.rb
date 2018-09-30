class StringFile < StringIO
  attr_accessor :original_filename

  def self.create(options = {})
    raise "needs body" if options[:body].blank?
    raise "needs name" if options[:name].blank?

    file = StringFile.new(options[:body])
    file.original_filename = options[:name]

    file
  end

  def content_type
    "text/plain"
  end
end
