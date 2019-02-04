

require 'sinatra'
require 'time'
require 'net/http'
require 'uri'
require 'json'
require 'data_mapper'
require 'dm-transactions'

require 'redis'
require 'haml'
require './settings'
require './models'
require './utils/utils'

require './controller/libraryspectrum_controller'

get '/' do
    haml :homepage
end

