require 'rufus-scheduler'
require 'httparty'

scheduler = Rufus::Scheduler.new

log_file = "log_continue_#{ENV['CI_BOX_ID']}.log"
file = File.open log_file

url = "#{ENV['DISCONTINUE_API']}/api/boxes/#{ENV['CI_BOX_ID']}/save_log_file"
HTTParty.post(
  url,
  body: {
    log: file.read
  }
)

def update_log_file(file)
  url = "#{ENV['DISCONTINUE_API']}/api/boxes/#{ENV['CI_BOX_ID']}/update_log_file"

  log = file.read
  if log.length > 0
    HTTParty.post(
      url,
      body: {
        log: log
      }
    )
  end
end

# sync log file
scheduler.interval '4s' do
  update_log_file(file)
end

# check for build script running
scheduler.interval '1s' do |job|
  `ps aux | grep -v grep | grep build_discontinue_`
  if $? != 0
    url = "#{ENV['DISCONTINUE_API']}/api/boxes/#{ENV['CI_BOX_ID']}/post_process"
    HTTParty.post(url)

    job.unschedule
  end
end

scheduler.join
