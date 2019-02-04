get '/libraryspectrum/aggregateview' do
    page_number, @previous_page, @next_page = page_prev_next_utilties(params)
    @page_number = page_number

    spectrumid = params[:spectrumid]
    compoundname = params[:compoundname]
    datasetid = params[:datasetid]

    if spectrumid == nil
        spectrumid = ""
    end

    if datasetid == nil
        datasetid = ""
    end

    if compoundname == nil
        compoundname = ""
    end


    #Web Rendering Code
    @spectrumid_input = spectrumid
    @datasetid_input = datasetid
    @compound_input = compoundname

    @param_string = "spectrumid=" + spectrumid + "&datasetid=" + datasetid + "&compoundname=" + compoundname

    query_parameters = Hash.new
    query_parameters[:offset]  = (page_number - 1) * PAGINATION_SIZE
    query_parameters[:limit]  = PAGINATION_SIZE

    count_parameters = Hash.new

    if compoundname.length > 2
        query_compoundname = "%" + compoundname + "%"
        query_parameters[:compoundname.like] = query_compoundname
        count_parameters[:compoundname.like] = query_compoundname
    end

    # if peptide.length > 2
    #     query_peptide = "%" + peptide + "%"
    #     peptides_db = Peptide.all(:sequence.like => query_peptide)
    #     query_parameters[:modificationpeptide] = ModificationPeptide.all(:peptide => peptides_db)
    #     count_parameters[:modificationpeptide] = ModificationPeptide.all(:peptide => peptides_db)
    # end

    # if modification.length > 2
    #     query_parameters[:name] = modification
    #     count_parameters[:name] = modification
    # end

    @all_library_spectrum = Libraryspectrum.all(query_parameters)
    @total_count = Libraryspectrum.count(count_parameters)

    if (@next_page - 1) * PAGINATION_SIZE > @total_count
        @next_page = nil
    end

    haml :libraryspectra
end

get '/libraryspectrum/:spectrumid' do
    spectrumid = params[:spectrumid]

    @library_spectrum = Libraryspectrum.first(:spectrumid => spectrumid)
    @datasets = @library_spectrum.dataset

    puts @datasets

    haml :libraryspectrum
end