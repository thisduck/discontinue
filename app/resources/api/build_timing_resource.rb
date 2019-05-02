class Api::BuildTimingResource < JSONAPI::Resource
  attributes :results

  belongs_to :build, always_include_linkage_data: true

  def results
    results = []
    times = []
    @model.streams.each do |stream|
      box_times = stream.boxes.collect(&:time_taken).sum
      times << box_times

      results << {
        name: stream.name,
        time: stream.humanized_time,
        total_time: HumanizeSeconds.humanize(box_times)
      }
    end

    results << {
      name: "Total",
      time: @model.humanized_time,
      total_time: HumanizeSeconds.humanize(times.sum)
    }
    results
  end

end
