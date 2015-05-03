require 'dm-migrations'
require 'dm-serializer'
require 'dm-constraints'

DataMapper::Property::String.length(255)

class Dataset
    include DataMapper::Resource
    property :id,               Serial
    property :name,             String
    property :task_id,          String
end



DataMapper.finalize
Dataset.auto_migrate! unless Dataset.storage_exists?
DataMapper.auto_upgrade!

