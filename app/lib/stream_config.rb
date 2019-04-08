# frozen_string_literal: true

class StreamConfig
  include ActiveModel::Validations

  validates_presence_of :name, :instance_type, :image_id
  validates :box_count, numericality: { greater_than: 0 }

  def initialize(config:, build_config:)
    @config = config
    @build_config = build_config
  end

  def build_config
    @build_config
  end

  def hash
    @hash ||=
      begin
        yaml = YAML.safe_load(@config) || {}
        yaml = {} unless yaml.is_a?(Hash)

        yaml
      end
  end

  # required
  def name
    hash['name']
  end

  def box_count
    hash['box_count']
  end

  def instance_type
    hash['instance_type'] || build_config.instance_type
  end

  def image_id
    ( hash['image_id'] || build_config.image_id)
  end

  # optional
  def environment_variables
    build_config.environment_variables.merge(
      hash['environment'] || {}
    )
  end

  def cache_dirs
    build_config.cache_dirs +
      (hash['cache_dirs'] || [])
  end

  def build_commands
    hash['build_commands']
  end

  def artifacts
    build_config.artifacts +
      ( hash['artifacts'] || [])
  end
end
