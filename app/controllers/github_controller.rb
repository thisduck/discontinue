class GithubController < ApplicationController
  def repositories
    render json: current_user.github.organizations.first.rels[:repos].get.data.collect(&:to_hash)
  end
end
