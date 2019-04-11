class BuildConfig
  include ActiveModel::Validations

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

  def setup_commands
    hash['setup_commands']
  end

  def environment_variables
    hash['environment'] || {}
  end

  def cache_dirs
    hash['cache_dirs'] || []
  end

  def artifacts
    hash['artifacts'] || []
  end

  def notification_options
    hash['notifications'] || []
  end

  def image_id
    hash['box_timeout']
  end

  def image_id
    hash['image_id']
  end

  def instance_type
    hash['instance_type']
  end
end
