require 'strava/api/v3'
require 'colorized_string'


@client = Strava::Api::V3::Client.new(:access_token => ENV["ACCESS_TOKEN"])
activities = @client.list_athlete_activities
activity = activities.first
full_activity = @client.retrieve_an_activity(activity['id'])

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
  when (0..2)
    :blue
  when (2..3)
    :yellow
  else
    :red
  end

  ColorizedString.new("#{grade}%").public_send(color)
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

full_activity['segment_efforts'].each do |segment_effort|
  segment_elapsed_time = segment_effort['elapsed_time']
  segment_distance = (segment_effort['segment']['distance'] / 1000.0).round(1)
  segment_name = segment_effort['segment']['name']
  segment_average_grade = segment_effort['segment']['average_grade']

  segment_leaderboard = @client.segment_leaderboards(segment_effort['segment']['id'])
  segment_kom_elapsed_time = segment_leaderboard['entries'].first['elapsed_time']

  your_speed = (segment_distance / segment_elapsed_time * 3600).round(1)
  kom_speed = (segment_distance / segment_kom_elapsed_time * 3600).round(1)

  puts "#{segment_name} - #{colorize_distance(segment_distance)} #{colorize_grade(segment_average_grade)}"
  puts "Your Speed: #{colorize_speed(your_speed)} KOM Speed: #{colorize_speed(kom_speed)}"
  puts
end
