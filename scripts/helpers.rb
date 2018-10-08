require 'aws-sdk-s3'
require 'yaml'

def expand_yaml(file)
  YAML.load File.read(File.expand_path(file))
end

def log(message)
  puts "[#{Time.now.to_s}]: #{message}"
end

def s3
  @s3 ||= Aws::S3::Resource.new(
    region: 'us-east-1'
  )
end

def s3_object_key(file, key:)
  [
    ENV['CI_REPO_NAME'],
    key,
    file
  ].compact.join("/")
end

def s3_bucket
  @s3_bucket ||= s3.bucket(ENV['S3_BUCKET'])
end

def s3_upload_file(key, file)
  object = s3_bucket.object(key)
  object.upload_file(file)
end
