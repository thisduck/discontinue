class Account < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :repositories
end
