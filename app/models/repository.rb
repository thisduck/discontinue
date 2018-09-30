class Repository < ApplicationRecord
  validates_presence_of :name, :github_id, :github_url
end
