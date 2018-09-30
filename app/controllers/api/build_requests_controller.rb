class Api::BuildRequestsController < ApiController

  def trigger_event
    build_request = BuildRequest.find params[:id]
    event = "#{params[:event]}!"
    build_request.send(event)
  end
end

