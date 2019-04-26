class BuildConfig
  include ActiveModel::Validations

  validates_presence_of :aws_access_key, :aws_access_secret, :aws_region, :aws_subnet_id, :aws_security_group_id, :aws_cache_bucket

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

  def box_timeout
    hash['box_timeout']
  end

  def image_id
    hash['image_id']
  end

  def instance_type
    hash['instance_type']
  end

  # required
  def aws_access_key
    hash['aws_access_key']
  end

  def aws_access_secret
    hash['aws_access_secret']
  end

  def aws_region
    hash['aws_region']
  end

  def aws_subnet_id
    hash['aws_subnet_id']
  end

  def aws_security_group_id
    hash['aws_security_group_id']
  end

  def aws_cache_bucket
    hash['aws_cache_bucket']
  end
end
