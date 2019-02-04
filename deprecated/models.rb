require 'dm-migrations'
require 'dm-serializer'
require 'dm-constraints'

DataMapper::Property::String.length(255)

class Dataset
    include DataMapper::Resource
    property :id,               Serial
    property :name,             String
    property :task_id,          String
    property :continuous_task_id, String

    has n, :datasetanalogs
    has n, :datasetidentifications
end


class Libraryspectrum
    include DataMapper::Resource
    property :id,               Serial
    property :spectrumid,       String
    property :compoundname,     String

    has n, :dataset, :through => :datasetLibraryspectrum
    has n, :datasetanalogs
end

class DatasetLibraryspectrum
    include DataMapper::Resource
    property :id,               Serial

    belongs_to :dataset
    belongs_to :libraryspectrum
end

class Datasetidentification
    include DataMapper::Resource
    property :id,               Serial
    property :scan,             String

    belongs_to :dataset
    belongs_to :libraryspectrum
end

class Datasetanalog
    include DataMapper::Resource
    property :id,               Serial
    property :scan,             String
    property :mz,               Integer

    belongs_to :dataset
    belongs_to :libraryspectrum
end

DataMapper.finalize
Dataset.auto_migrate! unless Dataset.storage_exists?
Libraryspectrum.auto_migrate! unless Libraryspectrum.storage_exists?
Datasetidentification.auto_migrate! unless Datasetidentification.storage_exists?
DatasetLibraryspectrum.auto_migrate! unless DatasetLibraryspectrum.storage_exists?
Datasetanalog.auto_migrate! unless Datasetanalog.storage_exists?
DataMapper.auto_upgrade!


