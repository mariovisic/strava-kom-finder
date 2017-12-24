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

helpers do
  def current_user
    DB[:users].where(username: session[:current_username]).first
  end

  def logged_in?
    !!current_user
  end
end

get '/' do
  erb :index, locals: { strava_redirect_uri: URI.join(ENV['STRAVA_REDIRECT_DOMAIN'], '/login').to_s, strava_client_id:  ENV['STRAVA_CLIENT_ID'] }
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
  puts 'here'
  puts current_user[:access_token].inspect
  puts params[:activity_id]
  client = Strava::Api::V3::Client.new(:access_token => current_user[:access_token])
  activity_data = client.retrieve_an_activity(params[:activity_id])
  activity_id = ActivityRepository.create(current_user[:id], activity_data)
  redirect "/activities/#{activity_id}"
end
