#!/usr/bin/env ruby

require 'json'
require './populate_settings'
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
    import_library_identification_results(continuous_id_task, dataset_id)
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
def import_library_identification_results(ci_task, dataset_id)
    root_url = "http://gnps.ucsd.edu"

    identification_information_url = root_url + "/ProteoSAFe/result_json.jsp" + "?task=" + ci_task + "&view=group_by_spectrum_all_beta"
    puts identification_information_url
    identification_data = JSON.parse(http_get(identification_information_url))["blockData"]

    identification_data.each {|identification_row|
        puts identification_row["SpectrumID"]
    }

end

#Takes a list of tab files, single threaded, one process
def import_all_tab_files(tabs_list, dataset_id, task_id, root_url)
    tabs_list.each { |tab_object| 
        tab_file = tab_object["MzTab_file"]
        import_dataset_tab_psm_file(dataset_id, task_id, tab_file, root_url)
    }
end

#Takes a list of tab files, multiprocess threaded
def import_all_tab_files_parallel(tabs_list, dataset_id, task_id, root_url)
    max_parallelism = 2
    running_parallelism = 0

    tabs_list.each { |tab_object| 
        tab_file = tab_object["MzTab_file"]
        
        running_parallelism += 1

        fork do
            #import_dataset_tab_psm_file(dataset_id, task_id, tab_file, root_url)
            import_tab_cmd = "ruby ./populate_parallel_tab.rb " 
            import_tab_cmd += dataset_id + " "
            import_tab_cmd += task_id + " "
            import_tab_cmd += tab_file + " "
            import_tab_cmd += root_url

            puts import_tab_cmd
            `#{import_tab_cmd}`

            abort
        end

        if running_parallelism == max_parallelism
            Process.waitall
            running_parallelism = 0
        end   
    }

    Process.waitall
end


def import_dataset_tab_psm_file(dataset_id, task_id, tsv_id, root_url)
    tab_information_url = root_url + "/ProteoSAFe/result_json.jsp?task=" + task_id + "&view=group_by_spectrum&file=" + tsv_id
    tab_data = JSON.parse(http_get(tab_information_url))["blockData"]

    puts "Parsing Tab: " + tsv_id + " with " + tab_data.length.to_s + " entries "
    
    psm_count = 0
    dataset_db = get_create_dataset(dataset_id, task_id)
    
    tab_data.each{ |psm_object|
        psm_count += 1
        #puts psm_count.to_s + " of " + tab_data.length.to_s
        spectrum_file = psm_object["#SpecFile"]
        scan =  psm_object["nativeID_scan"]
        peptide = psm_object["modified_sequence"]
        protein = psm_object["accession"]
        modification_string = psm_object["modifications"]

        #Adding Proteins
        protein_db = get_create_protein(protein)
        protein_dataset_join = create_dataset_protein_link(protein_db, dataset_db)

        modifications_list = Array.new
        if modification_string != "null"
            modifications_list = modification_string.split(',')
        end
	
        
        peptide_db, variant_db = get_create_peptide(peptide, dataset_db, protein_db)
        psm_db = get_create_psm(variant_db, dataset_db, protein_db, peptide_db, tsv_id, scan, spectrum_file, peptide)
        get_create_modification(modifications_list, peptide_db, variant_db, dataset_db, protein_db, psm_db)
        
    }
end
