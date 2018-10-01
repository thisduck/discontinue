require 'aws-sdk-s3'
require 'yaml'

def log(message)
  puts "[#{Time.now.to_s}]: #{message}"
end

option = ARGV.first
cache_directories = YAML.load File.read(File.expand_path('~/cache_file.yml'))
cache_directories = cache_directories.collect do |directory|
  if directory.start_with?("$")
    ENV[directory[1..-1]]
  else
    directory
  end
end

s3 = Aws::S3::Resource.new(
  region: 'us-east-1'
)

def object_key(file, branch: ENV["CI_BRANCH"])
  version = `cat /proc/version`.chomp
  if version.downcase.include?("ubuntu")
    version = "ubuntu"
  elsif version.downcase.include?("centos") || version.downcase.include?("red hat")
    version = "centos"
  else
    version = "other"
  end
  "#{ENV['CI_REPO_NAME']}/#{version}/#{branch}/#{ENV['CI_BUILD_STREAM_CONFIG']}/#{file}"
end

def tar_file_name(directory)
  directory.gsub(/\//, '_') + ".tar.gz"
end

bucket = s3.bucket(ENV['S3_BUCKET'])

case option
when "cache"
  cache_directories.each do |directory|
    tar_file = tar_file_name(directory)
    log "tarring #{directory}."
    if File.exist?(directory)
      `tar czf #{tar_file} #{directory}`
      log "tarring #{directory} complete."
      log "uploading #{tar_file} to S3."
      obj = bucket.object(object_key(tar_file))
      obj.upload_file(tar_file)
      log "uploading #{tar_file} to S3 complete."
    else
      log "#{directory} does not exist."
    end
  end
when "fetch"
  cache_directories.each do |directory|
    tar_file = tar_file_name(directory)
    obj = bucket.object(object_key(tar_file))
    log "checking #{tar_file} in S3."
     unless obj.exists?
      log "checking #{tar_file} on master in S3."
      obj = bucket.object(object_key(tar_file, branch: "master"))
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
