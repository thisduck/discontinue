class StreamConfig
  include ActiveModel::Validations

  validates_presence_of :name

  def initialize(config:)
    @config = config
  end

  def hash
    @hash ||=
      begin
        yaml = YAML.safe_load(@config) || {}
        yaml = {} unless yaml.is_a?(Hash)

        yaml
      end
  end

  def name
    hash['name']
  end
end
