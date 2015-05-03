#!/usr/bin/env ruby

require 'json'
require './populate_settings'
require './network_classes'
require '../models'
require 'net/http'


def http_get(url)
    url = URI.parse(url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    return res.body
end

def import_results_all_dataset()
    root_url = "http://gnps.ucsd.edu"
    all_datasets_list_url = root_url + "/ProteoSAFe/datasets_json.jsp"

    all_datasets_list = JSON.parse(http_get(all_datasets_list_url))["datasets"]

    all_datasets_list.each do |dataset_info|
        #Filtering to GNPS datasets
        if dataset_info["title"].downcase.index("gnps") != nil
            puts dataset_info["title"]
            puts dataset_info["dataset"]
            dataset_id = dataset_info["dataset"]
            import_results_dataset(dataset_id)
        end
    end
end

def import_results_dataset(dataset_id)
    #Get task_id for dataset_id
    #http://gnps.ucsd.edu/ProteoSAFe/MassiveServlet?massiveid=MSV000078711&function=massiveinformation
    root_url = "http://gnps.ucsd.edu"
    dataset_information = root_url + "/ProteoSAFe/MassiveServlet?massiveid=" + dataset_id + "&function=massiveinformation"
    puts dataset_information
    ###SHOULD CHECK IF DATASET IS ALREADY IN THERE, IF SO, STOP

    result = http_get(dataset_information)
    #print result
    
    dataset_information = JSON.parse(result)
    task_id = dataset_information["task"]
    
    #Now we have task id, we need to grab the list of continuous id jobs
    continuous_id_data_url = root_url + "/ProteoSAFe/ContinuousIDServlet?task=" + task_id
    continuous_id_runs = JSON.parse(http_get(continuous_id_data_url))["jobs"]
    
    continuous_id_task = get_most_recent_reported_ci_job(continuous_id_runs)
    if continuous_id_task == nil
        return
    end
    
    #Import information
    import_library_identification_results(continuous_id_task, dataset_id, task_id)
    import_network_information(continuous_id_task, dataset_id, task_id)
end

#Returns the task id of the most recent reported job, if non, returns nil
def get_most_recent_reported_ci_job(ci_list)
    ci_list.each { |ci_job|
        if ci_job["reported"] == "1"
            return ci_job["task"]
        end
    }
    return nil
end

#importing library identification results
def import_library_identification_results(ci_task, dataset_id, dataset_task)
    root_url = "http://gnps.ucsd.edu"

    identification_information_url = root_url + "/ProteoSAFe/result_json.jsp" + "?task=" + ci_task + "&view=group_by_spectrum_all_beta"
    puts identification_information_url
    identification_data = JSON.parse(http_get(identification_information_url))["blockData"]


    dataset_db = Dataset.first_or_create(:name => dataset_id, :task_id => dataset_task,
        :continuous_task_id => ci_task)

    identification_data.each {|identification_row|
        spectrumid = identification_row["SpectrumID"]
        compoundname = identification_row["Compound_Name"]
        libraryspectrum_db = Libraryspectrum.first_or_create(:spectrumid => spectrumid, :compoundname => compoundname)

        #Adding a connection between dataset to library spectrum
        spectrum_scan = identification_row["#Scan#"]

        Datasetidentification.first_or_create(
            :scan => spectrum_scan, 
            :dataset => dataset_db,
            :libraryspectrum => libraryspectrum_db)

        DatasetLibraryspectrum.first_or_create(
            :dataset => dataset_db,
            :libraryspectrum => libraryspectrum_db)
    }
end

#Importing the network
def import_network_information(ci_task, dataset_id, dataset_task)
    root_url = "http://gnps.ucsd.edu"

    dataset_db = Dataset.first(:name => dataset_id)

    all_identifications = Datasetidentification.all(:dataset => dataset_db)
    all_library_spectra = all_identifications.libraryspectrum

    network_pairs_url = root_url + "/ProteoSAFe/result_json.jsp" + "?task=" + ci_task + "&view=clusters_network_pairs"
    pairs_data = nil
    begin
        pairs_data = JSON.parse(http_get(network_pairs_url))["blockData"]
    rescue
        return
    end


    cluster_info_url = root_url + "/ProteoSAFe/result_json.jsp" + "?task=" + ci_task + "&view=view_all_clusters_withID"
    cluster_data = JSON.parse(http_get(cluster_info_url))["blockData"]

    #Creating Network Object
    network_object = Network.new
    cluster_data.each{ |cluster_datum|
        network_object.add_node(cluster_datum["cluster index"], 
            cluster_datum["parent mass"].to_i,
            cluster_datum["LibraryID"])
    }

    pairs_data.each{ |network_pair|
        network_object.add_edge(network_pair["Node1"], network_pair["Node2"])
    }


    #Find all neighbors for each library spectrum
    library_spectrum_to_neighbors = Hash.new
    library_spectrum_to_identified_neighbors = Hash.new
    library_spectrum_to_unidentified_neighbors = Hash.new

    all_library_spectra.each{ |library_spectrum|
        library_spectrum_to_neighbors[library_spectrum.spectrumid] = Array.new
        library_spectrum_to_identified_neighbors[library_spectrum.spectrumid] = Array.new
        library_spectrum_to_unidentified_neighbors[library_spectrum.spectrumid] = Array.new
    }

    all_identifications.each{ |identification|
        neighbors = network_object.get_node_neighbors(identification.scan)
        neighbors.each{ |neighbor|
            if network_object.get_node(neighbor).identification.length > 2
                library_spectrum_to_identified_neighbors[identification.libraryspectrum.spectrumid].push(neighbor)
            else
                library_spectrum_to_unidentified_neighbors[identification.libraryspectrum.spectrumid].push(neighbor)
            end
            library_spectrum_to_neighbors[identification.libraryspectrum.spectrumid].push(neighbor)
        }
    }

    #Going through the identified and unidentified lists
    library_spectrum_to_neighbors.each do |key, value|
        identified_mz_values = Hash.new
        unidentified_mz_values = Hash.new
        unidentified_neighbors = library_spectrum_to_unidentified_neighbors.keys
        
        library_spectrum_to_identified_neighbors[key].each do |id_neighbor|
            identified_mz_values[network_object.get_node(id_neighbor).mz] = 1
        end
        library_spectrum_to_unidentified_neighbors[key].each do |unid_neighbor|
            if identified_mz_values.has_key?(network_object.get_node(unid_neighbor).mz)
                puts "ALREADY ID'd"
            else
                unidentified_mz_values[network_object.get_node(unid_neighbor).mz] = 1
            end
            #Adding analog to database
            Datasetanalog.first_or_create(:scan => unid_neighbor, 
                :mz => network_object.get_node(unid_neighbor).mz,
                :dataset => dataset_db, 
                :libraryspectrum => Libraryspectrum.first(:spectrumid => key))
        end
        puts key
        puts unidentified_mz_values
        puts "Neighbor Nodes: " + value.length.to_s
        puts "Unidentified Neighbors Total: " + unidentified_neighbors.length.to_s
        puts "Unique Precursor Neighbors: " + (identified_mz_values.keys.length + unidentified_mz_values.keys.length).to_s
        puts "Unique Unidentified Neighbors: " + unidentified_mz_values.keys.length.to_s
    end
end