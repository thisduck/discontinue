module GithubEvents
  class Installation
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def handle
      installation_params = params['installation']
      sender_params = params['sender']
      repositories_params = params['repositories'] || []

      account = create_account installation_params

      if sender_params['type'] == 'User'
        user = create_user(sender_params, account)
      end

      repositories_params.each do |repo|
        create_repository repo, account
      end
    end

    def create_repository(repo, account, options = {})
      repository = Repository.where(
        integration_type: 'github',
        integration_id: repo['id'].to_s,
      ).first_or_create

      repository.update_attributes({
        name: repo['name'],
        full_name: repo['full_name'],
        private_repo: repo['private'],
        active: true,
        account: account
      }.merge(options))

      repository
    end

    def create_account(installation_params)
      account_params = installation_params['account']
      account = Account.where(
        integration_type: 'github', 
        integration_id: account_params['id']
      ).first_or_create

      account.update_attributes(
        integration_installation_id: installation_params['id'],
        integration_account_type: account_params['type'],
        name: account_params['login']
      )

      account
    end

    def create_user(sender_params, account)
      user = User.where(
        integration_type: 'github',
        integration_id: sender_params['id']
      ).first_or_create

      user.update_attributes({
        integration_login: sender_params['login'],
        avatar_url: sender_params['avatar_url'],
      })

      unless user.accounts.include?(account)
        user.accounts << account 
        user.save
      end

      user
    end

  end
end
