if Rails.configuration.x.demo_mode
  user = User.find_or_create_by!(integration_type: 'demo', integration_id: 'local') do |record|
    record.assign_attributes(email: 'demo@example.test', integration_login: 'demo', active: true)
  end
  account = Account.find_or_create_by!(integration_type: 'demo', integration_id: 'local') do |record|
    record.assign_attributes(name: 'Sample workspace', active: true)
  end
  user.accounts << account unless user.accounts.exists?(account.id)
  repository = account.repositories.find_or_create_by!(integration_type: 'demo', integration_id: 'sample') do |record|
    record.assign_attributes(name: 'sample-app', full_name: 'sample-workspace/sample-app', active: true, config: '{}')
  end
  account.repositories.find_or_create_by!(integration_type: 'demo', integration_id: 'empty') do |record|
    record.assign_attributes(name: 'empty-repo', full_name: 'sample-workspace/empty-repo', active: true, config: '{}')
  end

  Searchkick.callbacks(false) do
    %w[passed failed].each_with_index do |status, index|
      sha = Digest::SHA1.hexdigest("discontinue-demo-#{status}")
      branch = index.zero? ? 'main' : 'feature/improve-checkout'
      started = (index + 1).days.ago
      finished = started + 2.minutes
      hook = { head_commit: { message: index.zero? ? 'Set up the sample CI workflow' : 'Improve checkout validation',
                              author: { name: 'Sample Developer' } } }
      request = repository.build_requests.find_or_create_by!(sha: sha) do |record|
        record.assign_attributes(branch: branch, hook_hash: hook, aasm_state: 'queued')
      end
      build = repository.builds.find_or_create_by!(build_request: request, sha: sha) do |record|
        record.assign_attributes(branch: branch, hook_hash: hook, config: '{}', aasm_state: status,
                                 started_at: started, finished_at: finished, duration: 120)
      end
      stream = build.streams.find_or_create_by!(build_stream_id: "demo-#{status}") do |record|
        record.assign_attributes(name: 'Unit tests', config: '{}', aasm_state: status,
                                 started_at: started, finished_at: finished, duration: 120)
      end
      box = stream.boxes.find_or_create_by!(box_number: '1') do |record|
        record.assign_attributes(aasm_state: status, started_at: started, finished_at: finished)
      end
      box.test_results.find_or_create_by!(test_id: "checkout-#{status}") do |record|
        record.assign_attributes(build: build, stream: stream, test_type: 'rspec', status: status,
                                 description: 'validates a checkout address', file_path: 'spec/checkout_spec.rb',
                                 line_number: '12', duration: 1_000_000_000)
      end
    end
  end

  Build.reindex
  BuildRequest.reindex
end
