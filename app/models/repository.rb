require 'github_api'
class Repository < ApplicationRecord
  belongs_to :account
  has_many :builds
  has_many :build_requests

  validates_presence_of :name, :integration_type, :integration_id

  def yaml_config
    if config
      YAML.load(config)
    else
      {}
    end
  end

  def filter_branches
    @filter_branches ||= 
      begin
        branches = yaml_config['filter_branches'] || {}
        branches['exclude'] ||= []
        branches['include'] ||= ['*']
        branches
      end
  end

  # def url
  #   client = account.client
  #   repo = client.repo(integration_id.to_i)
  #   repo.ssh_url
  # end
end
