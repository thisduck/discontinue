module GithubEvents
  class Push
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def handle
      hook = GithubPushHook.new(params['github'])
      repo = Repository.where(
        integration_type: 'github',
        integration_id: hook.repository_id
      ).first

      if hook.branch.present?
        BuildRequest.add_request(
          branch: hook.branch,
          sha: hook.sha,
          hook_hash: hook.hash,
          repository: repo
        )
      end
    end
  end
end
