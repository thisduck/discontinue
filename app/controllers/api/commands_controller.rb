class Api::CommandsController < ApiController
  def index_related_resources
    box = visible_boxes.find(params[:box_id])
    render_virtual_collection(Api::CommandResource, box.commands.order)
  end
end

