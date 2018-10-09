class Repository < ApplicationRecord
  validates_presence_of :name, :github_id, :github_url

  def yaml_config
    YAML.load config
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
end
