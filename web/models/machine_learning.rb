class MachineLearning
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
    }
  end

  def load_training_data_for_user(user)
    training_data = SegmentEffortRepository.find_all_for_user_id(user[:id]).each do |segment_effort|
      api_data = JSON.parse(segment_effort[:api_data])
      segment_distance = api_data['segment']['distance']
      segment_average_grade = api_data['segment']['average_grade']
      your_time = api_data['athlete_segment_stats']['pr_elapsed_time']
      your_speed = (segment_distance / your_time) * 3.6

      train(segment_distance, segment_average_grade, your_speed)
    end
  end

  def train(distance, average_grade, speed)
    @training_set.push([distance, average_grade, speed])
  end

  def tune
    iterations = 10_000
    change_value = 0.001
    iterations.times do |i|
      current_loss = mean_squared_loss
      (@learnt_values.keys.map do |key|
        test_value_change(current_loss, key, change_value) ||
        test_value_change(current_loss, key, -change_value)
      end).any? || puts("Done tuning, ran #{i} loops") || break
    end

    puts @learnt_values.inspect
  end

  def predict_speed(distance, average_grade, learnt_values = @learnt_values)
    # FIXME: Currently we're minusing the distance as a modifier, it would better to multiply it I think
    # but I was having troubles getting it into a 0-1 range
    (((Math.log((average_grade * learnt_values[:a]) + learnt_values[:b],
              learnt_values[:c]) * learnt_values[:d]) - learnt_values[:e] -
    (learnt_values[:f] * average_grade)) - (Math.log(distance + 1, learnt_values[:g]) * learnt_values[:h])) * learnt_values[:i]
  end

  def mean_squared_loss(learnt_values = @learnt_values)
    losses = @training_set.map { |set| (set[2] - predict_speed(set[0], set[1], learnt_values))**2 }

    (losses.inject(:+) / losses.to_a.count)
  end

  private

  def test_value_change(starting_loss, key, change)
    test_values = @learnt_values.dup
    test_values[key] += change
    new_loss = mean_squared_loss(test_values) 


    if new_loss < starting_loss
      puts "tweaked :#{key} accepting change with new loss: #{new_loss.round(2)}"
      @learnt_values = test_values
    end
  end

  def program
    SupervisedLearning::LinearRegression.new(Matrix[*@training_set])
  end
end
