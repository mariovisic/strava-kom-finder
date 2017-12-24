require 'bundler'
Bundler.setup

require 'dotenv/load'
require 'sinatra'

get '/' do
  erb :index, locals: { strava_redirect_uri: URI.join(ENV['STRAVA_REDIRECT_DOMAIN'], '/login').to_s, strava_client_id:  ENV['STRAVA_CLIENT_ID'] }
end

get '/login' do
  raise params.inspect
end
