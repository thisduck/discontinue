file_dir = __dir__
require file_dir + '/helpers.rb'

artifacts = expand_yaml('~/artifacts.yml')

# repo/build/stream/box


def artifact_key(file)
  key = [
    'artifacts',
    "build_#{ENV['CI_BUILD_ID']}",
    "stream_#{ENV['CI_STREAM_ID']}",
    "box_#{ENV['CI_BOX_ID']}",
  ].join("/")

  s3_object_key(file, key: key)
end

artifacts.each do |artifact|
  paths = Dir[artifact]
  paths.each do |path|
    files = []
    if File.directory?(path)
      files = files + Dir[path + '/**/*']
    else
      files << path
    end

    log "#{files.count} files to upload."

    files.each do |file|
      key = artifact_key(file)
      log "Uploading #{key}."
      s3_upload_file(key, file)
    end
  end
end
