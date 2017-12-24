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
require 'config/database'

enable :sessions

require 'models/user_repository'
require 'models/activity_repository'
require 'models/segment_effort_repository'

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
  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  activity_data = client.retrieve_an_activity(params[:activity_id])
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
  erb :map
end

get '/segments' do
  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  segments = client.segment_explorer(bounds: params[:bounds])

  content_type :json
  JSON.dump(segments)
end
