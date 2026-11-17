class Api::ArtifactResource < JSONAPI::Resource
  attributes :key, :filename, :extension, :size, :presigned_url, :box_id

  key_type :uuid
  has_one :box
end
