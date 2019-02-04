


def page_prev_next_utilties(params)
	page_number = 1
    if params[:page] != nil
        page_number = params[:page].to_i
    end

    #Determining next and prev page
    if page_number == 1
        next_page = page_number + 1
        previous_page = nil
    else
        next_page = page_number + 1
        previous_page = page_number - 1
    end

    return page_number, previous_page, next_page
end