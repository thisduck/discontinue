module GithubEvents
  class IntegrationInstallationRepository < ::GithubEvents::Installation

    def handle
      account_params = params['installation']['account']
      sender_params = params['sender']
      repositories_added = params['repositories_added'] || []
      repositories_removed = params['repositories_removed'] || []

      account = create_account account_params
      user = create_user(sender_params, account) if sender_params['type'] == 'User'

      repositories_added.each do |repo|
        create_repository repo, account
      end

      repositories_removed.each do |repo|
        remove_repository repo, account
      end
    end

    def remove_repository(repo, account)
      create_repository(repo, account, active: false)
    end
  end
end
