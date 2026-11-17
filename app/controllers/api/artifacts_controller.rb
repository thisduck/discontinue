class Api::ArtifactsController < ApiController
  def index_related_resources
    source = if params[:test_result_id]
      TestResult.where(box_id: visible_boxes.select(:id)).find(params[:test_result_id])
    else
      visible_boxes.find(params[:box_id])
    end
    render_virtual_collection(Api::ArtifactResource, source.artifacts.order)
  end
end

