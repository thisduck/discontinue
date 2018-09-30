class Api::BuildsController < ApiController

  def trigger_event
    build_request = Build.find params[:id]
    event = "#{params[:event]}!"
    build_request.send(event)
  end
end

