require 'json'
require 'net/http'

uri = URI(ENV.fetch('DEMO_URL', 'http://127.0.0.1:3000'))
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = uri.scheme == 'https'
headers = { 'Accept' => 'application/vnd.api+json' }

def expect_status(response, status)
  abort "Expected HTTP #{status}, got #{response.code}" unless response.code.to_i == status
  response.body
end

expect_status(http.get('/up'), 200)
expect_status(http.get('/api/builds', headers), 401)
expect_status(http.post('/session', '{}', 'Content-Type' => 'application/json'), 401)
login = http.post('/session', '{"demo":true}', 'Content-Type' => 'application/json')
headers['Authorization'] = "Bearer #{JSON.parse(expect_status(login, 200)).fetch('token')}"
expect_status(http.post('/api/repositories', '{}', headers), 403)
expect_status(http.get('/github/repositories', headers), 403)

read = ->(path) { JSON.parse(expect_status(http.get("/api/#{path}", headers), 200)).fetch('data') }
abort 'Expected the local demo identity' unless read.call('users/current').dig('attributes', 'email') == 'demo@example.test'
abort 'Expected sample repositories' unless read.call('repositories').size == 2
abort 'Expected a passed and a failed build' unless read.call('builds').map { |r| r.dig('attributes', 'state') }.sort == %w[failed passed]
matches = read.call('builds?filter%5Bquery%5D=checkout&sort=-created-at')
abort 'Expected one failed build from OpenSearch' unless matches.one? && matches.first.dig('attributes', 'state') == 'failed'
build = matches.first.fetch('id')
abort 'Expected a repository for the build' unless read.call("builds/#{build}/repository").dig('attributes', 'name') == 'sample-app'
summary = read.call("builds/#{build}/build-summary")
abort 'Expected a failed test summary' unless summary.dig('attributes', 'results', 0, 'status') == 'failed'
puts 'Demo API: login, access restrictions, fixtures, search and build summary passed'