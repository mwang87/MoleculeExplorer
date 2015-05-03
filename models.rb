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


class Libraryspectrum
    include DataMapper::Resource
    property :id,               Serial
    property :spectrumid,       String
    property :compoundname,     String
end

class Datasetidentification
    include DataMapper::Resource
    property :id,               Serial
    property :scan,             String

    belongs_to :dataset
    belongs_to :libraryspectrum
end

DataMapper.finalize
Dataset.auto_migrate! unless Dataset.storage_exists?
Libraryspectrum.auto_migrate! unless Libraryspectrum.storage_exists?
Datasetidentification.auto_migrate! unless Datasetidentification.storage_exists?
DataMapper.auto_upgrade!


