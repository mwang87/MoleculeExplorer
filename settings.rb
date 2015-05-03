require 'data_mapper'
require 'redis'



PAGINATION_SIZE = 10

puts ENV["RACK_ENV"]
configure :test do
    DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/data.db")
end
configure :development do
    DataMapper.setup(:default, ENV['DATABASE_URL'] )
end
configure :production do
	require 'newrelic_rpm'
    DataMapper.setup(:default, ENV['DATABASE_URL'] )
end

def setting_initialize()

    puts "SETTINGS INITIALIZE"
    
end
