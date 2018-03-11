require 'bundler'
Bundler.setup

$LOAD_PATH.push(File.dirname(File.expand_path(__FILE__)))

require 'sinatra'

if development?
  require 'dotenv'
  require 'sinatra/reloader'
  Dotenv.overload
end

require 'strava/api/v3'
require 'matrix'
require 'supervised_learning'
require 'concurrent'

require 'config/database'

enable :sessions

require 'models/activity_repository'
require 'models/machine_learning'
require 'models/parallel_execution'
require 'models/segment_effort_repository'
require 'models/segment_leaderboard_repository'
require 'models/user_repository'

helpers do
  def current_user
    !!session[:current_username] && DB[:users].where(username: session[:current_username]).first
  end

  def logged_in?
    !!current_user
  end

  def current_activities
    current_user && DB[:activities].where(user_id: current_user[:id])
  end
end

get '/' do
  erb :index, locals: { strava_redirect_uri: URI.join(ENV['STRAVA_REDIRECT_DOMAIN'], '/login').to_s, strava_client_id:  ENV['STRAVA_CLIENT_ID'], current_activities: current_activities }
end

get '/login' do
  access_information = Strava::Api::V3::Auth.retrieve_access(ENV['STRAVA_CLIENT_ID'], ENV['STRAVA_CLIENT_SECRET'], params[:code])
  access_token = access_information['access_token']
  athlete_information = access_information['athlete']

  if athlete_information
    user = UserRepository.create_or_update(access_token, athlete_information)
    session[:current_username] = athlete_information['username']
  end

  redirect '/'
end

get '/logout' do
  session[:current_username] = nil

  redirect '/'
end

post '/activities' do
  activity_id = params[:activity_id].scan(/\d/).join('')
  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  activity_data = client.retrieve_an_activity(activity_id)
  activity_id = ActivityRepository.create(current_user[:id], activity_data)
  redirect '/'
end

get '/activities/:id' do
  activity = DB[:activities].where(user_id: current_user[:id], id: params[:id]).first

  erb :activity, locals: { activity: activity }
end

get '/activities/:id/download' do
  activity = DB[:activities].where(user_id: current_user[:id], id: params[:id]).first
  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  segment_effort = JSON.parse(activity[:api_data])['segment_efforts'][activity[:downloaded_segment_efforts]]
  full_segment_effort_info = client.retrieve_a_segment_effort(segment_effort['id'])
  SegmentEffortRepository.create(activity[:id], full_segment_effort_info)

  content_type :json
  JSON.dump(DB[:activities].where(user_id: current_user[:id], id: params[:id]).first)
end


get '/map' do
  erb :map, layout: true
end

get '/segments' do
  # TODO: Refactor all this into a class :)
  training_data = SegmentEffortRepository.find_all_for_user_id(current_user[:id]).map do |segment_effort|
    api_data = JSON.parse(segment_effort[:api_data])
    segment_distance = api_data['segment']['distance']
    segment_average_grade = api_data['segment']['average_grade']
    your_time = api_data['athlete_segment_stats']['pr_elapsed_time']

    [ segment_distance, segment_average_grade, your_time ]
  end

  training_set = Matrix[*training_data]
  program = SupervisedLearning::LinearRegression.new(training_set)

  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  segments = client.segment_explorer(bounds: params[:bounds]).fetch('segments')

  ParallelExecution.perform(segments) do |segment|
    prediction_set = Matrix[ [segment.fetch('distance'), segment.fetch('avg_grade')] ]

    segment[:leaderboard] = SegmentLeaderboardRepository.fetch_or_create(client, segment['id'])
    segment[:predicted_time] = program.predict(prediction_set).round(0)
  end

  segments = segments.select { |segment| segment[:predicted_time] > 0 }

  content_type :json
  JSON.dump(segments)
end

get '/debug' do
  machine_learning = MachineLearning.new
  machine_learning.load_training_data_for_user(current_user)

  @grade_speed_data = machine_learning.training_set.map do |data_point|
    [data_point.average_grade, data_point.speed, machine_learning.predict_speed(data_point.distance, data_point.average_grade)]
  end

  @distance_speed_data = machine_learning.training_set.map do |data_point|
    [(data_point.distance / 1000.0).round(2), data_point.speed, machine_learning.predict_speed(data_point.distance, data_point.average_grade)]
  end

  machine_learning.tune

  @average_mean_squared_loss = machine_learning.mean_squared_loss

  erb :debug
end
