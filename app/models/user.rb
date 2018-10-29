# frozen_string_literal: true

class User < ApplicationRecord
  has_and_belongs_to_many :accounts

  validates_presence_of :integration_type, :integration_id
  validates_presence_of :integration_type, :integration_id

  def github
    client = Octokit::Client.new(access_token: access_token)
  end
end
