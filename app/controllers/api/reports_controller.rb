class Api::ReportsController < ApplicationController
  def build_status
    data = Build::Reports.status(branch: "master")
    render json: data
  end

  def most_failed
    data = TestResult::Reports.most_failed(branch: "master")
    render json: data
  end
end
