require 'strava/api/v3'
require 'colorized_string'
require 'matrix'
require 'supervised_learning'

training_data = []

client = Strava::Api::V3::Client.new(:access_token => ENV["ACCESS_TOKEN"])
activities = client.list_athlete_activities
activity = activities.first
full_activity = client.retrieve_an_activity(activity['id'])

def colorize_distance(distance)
  color = case distance
  when (0..0.5)
    :green
  when (0.5..2)
    :blue
  when (2..5)
    :yellow
  else
    :red
  end

  ColorizedString.new("#{distance}km").public_send(color)
end

def colorize_grade(grade)
  color = case grade
  when (-Float::INFINITY..-0.01)
    :green
  when (0..2.5)
    :blue
  when (2.5..4)
    :yellow
  else
    :red
  end

  leading_space = grade > 0 ? ' ' : ''
  ColorizedString.new("#{leading_space}#{grade}%").public_send(color)
end


def colorize_speed(speed)
  color = case speed
  when (0..15)
    :red
  when (15..30)
    :yellow
  when (30..40)
    :blue
  else
    :green
  end

  ColorizedString.new("#{speed} km/h").public_send(color)
end

def colorize_diff_speed(kom_speed, your_speed)
  color = case (your_speed / kom_speed.to_f)
  when (0..0.7)
    :red
  when (0.7..0.8)
    :yellow
  when (0.8..0.9)
    :blue
  else
    :green
  end

  ColorizedString.new("#{(kom_speed - your_speed).round(1)} km/h").public_send(color)
end


puts "#{'Name'.ljust(30)} | #{'Distance'.ljust(8)} | #{'Grade'.ljust(8)} | #{'PR Speed'.ljust(10)} | #{'KOM Speed'.ljust(10)} | #{'Pred Speed'.ljust(10)} | #{'Speed Diff (Prediction vs KOM)'.ljust(30)}"
puts "-" * 120


output_data = []

full_activity['segment_efforts'].each do |segment_effort|
  full_segment_info = client.retrieve_a_segment(segment_effort['segment']['id'])
  segment_pr_elapsed_time = full_segment_info['athlete_segment_stats']['pr_elapsed_time']
  segment_distance = (segment_effort['segment']['distance'] / 1000.0).round(1)
  segment_name = segment_effort['segment']['name']
  segment_average_grade = segment_effort['segment']['average_grade']

  segment_leaderboard = client.segment_leaderboards(segment_effort['segment']['id'])
  segment_kom_elapsed_time = segment_leaderboard['entries'].first['elapsed_time']

  your_speed = (segment_distance / segment_pr_elapsed_time * 3600).round(1)
  kom_speed = (segment_distance / segment_kom_elapsed_time * 3600).round(1)

  output_data.push(
    segment_name: segment_name,
    segment_distance: segment_distance,
    segment_average_grade: segment_average_grade,
    your_speed: your_speed,
    kom_speed: kom_speed
  )

  training_data.push([segment_distance, segment_average_grade, your_speed])
end

training_set = Matrix[*training_data]
program = SupervisedLearning::LinearRegression.new(training_set)

output_data.each do |effort|
    segment_name = effort[:segment_name]
    segment_distance = effort[:segment_distance]
    segment_average_grade = effort[:segment_average_grade]
    your_speed = effort[:your_speed]
    kom_speed = effort[:kom_speed]
    prediction_set = Matrix[ [segment_distance, segment_average_grade] ]
    predicted_speed = program.predict(prediction_set).round(1)

    puts "#{segment_name[0,30].ljust(30)} | #{colorize_distance(segment_distance).ljust(8 + 14)} | #{colorize_grade(segment_average_grade).ljust(8 + 14)} | #{colorize_speed(your_speed).ljust(10 + 14)} | #{colorize_speed(kom_speed).ljust(10 + 14)} | #{colorize_speed(predicted_speed).ljust(10 + 14)} | #{colorize_diff_speed(kom_speed, predicted_speed).ljust(10 + 14)} "
end


@program = program
require 'debug'
true
true
