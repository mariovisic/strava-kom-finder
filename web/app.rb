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
