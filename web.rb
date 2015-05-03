

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

get '/' do
    haml :homepage
end








get '/peptide/querymod/:peptide' do
    query_peptide = params[:peptide]
    peptide_object = Basicpeptide.first(:sequence => query_peptide)
    
    if peptide_object == nil
        return "{}"
    end
    
    return peptide_object.peptides.to_json()
end



get '/protein/all.json' do
    return Protein.all.to_json
end

get '/protein/query/:protein' do
    query_protein = params[:protein]
    protein_object = Protein.first(:name => query_protein)
    
    if protein_object == nil
        return "{}"
    end
    
    return protein_object.datasets.to_json()
end

get '/peptide/create' do
    haml :peptidecreatelink
end

post '/peptide/create' do
    puts params
    peptide = params[:peptide]
    dataset = params[:dataset]
    
    peptide_db = get_create_peptide(peptide)
    puts peptide_db
    dataset_db = get_create_dataset(dataset)
    puts dataset_db
    
    join_db = create_dataset_peptide_link(peptide_db, dataset_db)
    
    if(join_db == nil)
        return "DNS"
    end
    
    return "SAVED"
end

get '/protein/create' do
    haml :proteincreatelink
end

post '/protein/create' do
    puts params
    protein = params[:protein]
    dataset = params[:dataset]
    
    protein_db = get_create_protein(protein)
    dataset_db = get_create_dataset(dataset)
    
    join_db = create_dataset_protein_link(protein_db, dataset_db)
    
    if(join_db == nil)
        return "DNS"
    end
    
    return "SAVED"
end
