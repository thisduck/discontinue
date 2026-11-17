class ApiController < JSONAPI::ResourceController
  include AuthenticationHelper
  prepend_before_action :restrict_demo_writes
  before_action :authenticate

  def context
    {
      current_user: current_user
    }
  end

  private

  def visible_boxes
    Box.where(stream_id: Stream.where(build_id: current_user.builds.select(:id)).select(:id))
  end

  def render_virtual_collection(resource_class, records)
    serializer = JSONAPI::ResourceSerializer.new(resource_class)
    data = records.map { |record| serializer.object_hash(resource_class.new(record, context), {}) }
    render json: { data: data }, content_type: 'application/vnd.api+json'
  end

  def restrict_demo_writes
    head :forbidden if Rails.configuration.x.demo_mode && !request.get? && !request.head?
  end
end
