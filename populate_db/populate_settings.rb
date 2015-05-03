require 'data_mapper'


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/data.db")
#DataMapper.setup(:default, 'postgres://postgres:postgres@localhost/proxi-demo' )
