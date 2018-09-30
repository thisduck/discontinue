# frozen_string_literal: true

class User < ApplicationRecord
  validates_presence_of :email
  validates_uniqueness_of :email

  def github
    client = Octokit::Client.new(access_token: access_token)
  end
end
