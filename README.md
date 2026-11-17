# Discontinue

A CI Server for folks who know how to get around a server.

## Local development

Use Ruby 3.3 (see `.ruby-version`), Bundler 2.5, Node 22 and Yarn Classic 1.22.
Building the `mysql2` gem requires a C compiler and MySQL/MariaDB client headers.
Run MySQL 8.4, Redis 7.4 and OpenSearch 2.19 locally; set `DATABASE_URL`, `REDIS_URL`
and `OPENSEARCH_URL` to those local services. Create an empty MySQL database and
grant its local user access before running setup.

```sh
export RAILS_ENV=development DISCONTINUE_DEMO=1 JOBS=1
bundle install
yarn --cwd frontend install --frozen-lockfile --non-interactive
bundle exec rails db:migrate db:seed
bundle exec puma -C config/puma.rb
```

Run `bundle exec rake jobs:work` in another terminal with the same environment.
Open `http://localhost:3000`, choose **Open sample workspace**, and go to **Builds**
or **Repositories**. The seed includes passed and failed builds and test results.
Setup can run again without duplicating the fixtures. Run `ruby scripts/smoke_demo.rb`
against the running demo to check the main API paths.

Demo mode is development-only and read-only. It does not use GitHub, run EC2
builds, upload artifacts or send mail. For a separate integration environment,
configure a test GitHub App (`GITHUB_APP_ID`, `GITHUB_APP_CLIENT_ID`,
`GITHUB_APP_CLIENT_SECRET`, `GITHUB_PEM`, `GITHUB_WEBHOOK_SECRET`) and set
`JWT_SECRET`. Do not expose the legacy runner endpoints publicly; they need
authentication and a security review before enabling real cloud runners.
