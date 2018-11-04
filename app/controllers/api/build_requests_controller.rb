class Api::BuildRequestsController < ApiController

  def trigger_event
    build_request = BuildRequest.find params[:id]
    event = "#{params[:event]}!"
    build_request.send(event)
  end

  def build_from_pull
    repository_id = params[:repository_id]
    repository = Repository.find repository_id
    number = params[:number]

    # binding.pry

    pull = repository.account.client.pull_request(repository.integration_id.to_i, number.to_i)
    commit = pull.rels[:commits].get.data.first[:commit].to_hash
    build_request = BuildRequest.create(
      branch: pull[:head][:ref],
      sha: pull[:head][:sha],
      hook_hash: {head_commit: commit},
      repository: repository,

    )
    build_request.queue!
    build = build_request.builds.last

    render json: {build: build}
  end


  def build_from_branch
    repository_id = params[:repository_id]
    repository = Repository.find repository_id
    branch_name = params[:branch]

    branch = repository.account.client.branch(repository.integration_id.to_i, branch_name).to_hash
    commit = branch[:commit]
    build_request = BuildRequest.create(
      branch: branch[:name],
      sha: commit[:sha],
      hook_hash: {head_commit: commit},
      repository: repository,

    )
    build_request.queue!
    build = build_request.builds.last

    render json: {build: build}
  end
end
