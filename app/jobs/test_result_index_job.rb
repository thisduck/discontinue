class TestResultIndexJob < ApplicationJob
  queue_as :default

  def perform(model_class, model_id)
    model = model_class.find model_id

    model.test_results.includes(:box, :build, :stream).find_in_batches(batch_size: 3000) do |group|
      Searchkick.callbacks(:bulk) do
        group.each &:reindex
      end
    end
  end

end
