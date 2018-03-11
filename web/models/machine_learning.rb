class MachineLearning
  TrainingDataPoint = Struct.new(:distance, :average_grade, :speed)
  attr_reader :training_set

  def initialize
    @training_set = []
    @learnt_values = {
      a: -0.2,
      b: 14,
      c: 10,
      d: 60,
      e: 30,
      f: 1.25,
      g: 2,
      h: 1,
      i: 1.2,
      j: 0
    }
  end

  def load_training_data_for_user(user)
    (SegmentEffortRepository.find_all_for_user_id(user[:id]).reject do |segment_effort|
      api_data = JSON.parse(segment_effort[:api_data])
      api_data['athlete_segment_stats']['effort_count'] <= 10
    end).each do |segment_effort|
      api_data = JSON.parse(segment_effort[:api_data])
      segment_distance = api_data['segment']['distance']
      segment_average_grade = api_data['segment']['average_grade']
      your_time = api_data['athlete_segment_stats']['pr_elapsed_time']
      your_speed = (segment_distance / your_time) * 3.6

      train(segment_distance, segment_average_grade, your_speed)
    end
  end

  def train(distance, average_grade, speed)
    @training_set.push(TrainingDataPoint.new(distance, average_grade, speed))
  end

  def tune
    iterations = 2_500
    change_values = [5, 1, 0.1, 0.01, 0.001, 0.0001]

    iterations.times do |i|
      current_loss = mean_squared_loss
      (@learnt_values.keys.map do |key|
        change_values.any? do |change_value|
          test_value_change(current_loss, key, change_value) ||
          test_value_change(current_loss, key, -change_value)
        end
      end).any? || puts("Done tuning, ran #{i} loops") || break
    end

    puts @learnt_values.inspect
  end

  def predict_speed(distance, average_grade, learnt_values = @learnt_values)
    # FIXME: Currently we're minusing the distance as a modifier, it would better to multiply it I think
    # but I was having troubles getting it into a 0-1 range
    (((((Math.log((average_grade * learnt_values[:a]) + learnt_values[:b],
              learnt_values[:c]) * learnt_values[:d]) - learnt_values[:e] -
    (learnt_values[:f] * average_grade)) - (Math.log(distance + 1, learnt_values[:g]) * learnt_values[:h]))) * \
    learnt_values[:i]) + learnt_values[:j]
  rescue Math::DomainError
    Float::MAX
  end

  def mean_squared_loss(learnt_values = @learnt_values)
    losses = @training_set.map do |data_point|
      (data_point.speed - predict_speed(data_point.distance, data_point.average_grade, learnt_values))**2
    end

    losses.inject(:+) / losses.count
  end

  private

  def test_value_change(starting_loss, key, change)
    test_values = @learnt_values.dup
    test_values[key] += change
    new_loss = mean_squared_loss(test_values) 


    if new_loss < starting_loss
      puts "tweaked :#{key} accepting #{change} change with new loss: #{new_loss.round(2)}"
      @learnt_values = test_values
    end
  end
end
