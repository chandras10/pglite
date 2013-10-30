module DatatablesHelper
  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end

  def quick_search(columns)
  	
  	criteria = []
  	terms = {}
  	which_one = -1
  	(0..(params['iColumns']).to_i).each do |i|
  		if params["sSearch_#{i}"].present?
  		   which_one += 1
           criteria << "(#{columns[i]} ILIKE :search#{which_one})"
           terms["search#{which_one}".to_sym] = "%" + params["sSearch_#{i}"] + "%"
  	    end
    end

    criteria = criteria.join(' and ')
    [criteria, terms]

  end
end