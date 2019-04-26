module GithubEvents
  class Push
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def log(hash)
      dir = "#{Rails.root}/tmp/push"
      filename = "#{dir}/#{Time.now.to_s.parameterize}-#{rand(1000)}.json"
      FileUtils.mkdir_p dir

      File.open(filename, "w") do |f|
        f.puts hash.to_json if hash
      end
    end

    def handle
      log(params['github'])

      hook = GithubPushHook.new(params['github'])
      repo = Repository.where(
        integration_type: 'github',
        integration_id: hook.repository_id
      ).first

      if hook.branch.present? && !hook.sha.include?("00000000")
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
