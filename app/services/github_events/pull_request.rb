module GithubEvents
  class PullRequest
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def log(hash)
      dir = "#{Rails.root}/tmp/pull_request"
      filename = "#{dir}/#{Time.now.to_s.parameterize}-#{rand(1000)}.json"
      FileUtils.mkdir_p dir

      File.open(filename, "w") do |f|
        f.puts hash.to_json if hash
      end
    end

    def handle
      log(params['github'])

      return unless params['github']['action'] == "opened"

      sha = params['github']['pull_request']['head']['sha']
      build_request = BuildRequest.where(sha: sha).first

      return unless build_request 
      return if build_request.queued?

      build_request.queue! unless build_request.ignore_build?
    end
  end
end
