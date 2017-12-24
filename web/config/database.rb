require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URI'])

Sequel.extension :migration
