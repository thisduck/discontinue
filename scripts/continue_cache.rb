file_dir = __dir__
require file_dir + '/helpers.rb'
require 'faraday'

option = ARGV[0]
key = ARGV[1]
directory = ARGV[2]

log "Entering discontinue cache with [#{option}]."

if key && !directory
  raise "key passed without directory/file."
end

cache_directories = expand_yaml('~/cache_file.yml').collect do |dir|
  if dir.start_with?("$")
    ENV[dir[1..-1]]
  else
    dir
  end
end

def cache_key(file, branch: ENV["CI_BRANCH"])
  key = [
    'cache',
    branch,
    ENV['CI_STREAM_CONFIG']
  ].join('/')

  s3_object_key(file, key: key)
end

def tar_file_name(directory)
  directory.gsub(/\//, '_') + ".tar.gz"
end

branch = ENV['CI_BRANCH']

if key
  cache_directories = [directory]
  branch = key
end

case option
when "cache"

  unless key
    url = "#{ENV['DISCONTINUE_API']}/api/boxes/#{ENV['CI_BOX_ID']}/cached"
    redis_key = "discontinue_#{ENV['CI_BUILD_STREAM_CONFIG']}_cache"
    response = Faraday.post(url, redis_key: redis_key)

    if response.body == "true"
      puts "Already cached. Exiting."
      exit 0
    end
  end

  cache_directories.each do |directory|
    tar_file = tar_file_name(directory)
    log "tarring #{directory}."
    if File.exist?(directory)
      `tar czf #{tar_file} #{directory}`
      log "tarring #{directory} complete."
      log "uploading #{tar_file} to S3."
      s3_upload_file(
        cache_key(tar_file, branch: branch),
        tar_file,
      )
      log "uploading #{tar_file} to S3 complete."
    else
      log "#{directory} does not exist."
    end
  end
when "fetch"
  cache_directories.each do |directory|
    tar_file = tar_file_name(directory)
    obj = s3_bucket.object(cache_key(tar_file, branch: branch))
    log "checking #{tar_file} in S3."
    unless obj.exists?
      log "checking #{tar_file} on master in S3."
      obj = s3_bucket.object(cache_key(tar_file, branch: "master"))
    end
    if obj.exists?
      log "downloading #{tar_file} from S3."
      obj.download_file(tar_file)
      log "downloading #{tar_file} from S3 complete."
      log "untarring #{tar_file}."
      `tar xzf #{tar_file}`
      log "untarring #{tar_file} complete."
    end
  end
end
