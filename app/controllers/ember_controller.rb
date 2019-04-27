class EmberController < ApplicationController
  skip_before_action :authenticate

  def index
    path = File.join(Rails.root, 'public', 'index.html')
    render html: File.read(path).html_safe
  end
end
