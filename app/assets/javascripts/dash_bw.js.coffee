# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  #
  # Hide the graph by default. It is drawn only on-demand!
  #
  $("#graphBox .btn-minimize").parent().parent().next('.box-content').slideToggle()
  $("#graphBox .btn-minimize i").removeClass('icon-chevron-up').addClass('icon-chevron-down')
  $("#graphLoadingIndicator").hide()
  url = window.location.href
  queryParams = $('<a>', { href: url})[0]
  if (!queryParams.search)
    queryParams.search = "?dummy=foobar"
  serverTable = $('#serverListTable').dataTable
    sDom: "Rlfrtp"
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: '/dash_bw.json' + queryParams.search
    bDeferRender: true
    bStateSave: false
    sScrollX: "100%"
    bScrollCollapse: true
    aoColumns: [
                   { mData: "key"},
                   { mData: "sent", sClass: "right"},
                   { mData: "recd", sClass: "right"},
                   { mData: "total", sClass: "right"}
                 ]      
  serverTable.fnSetFilteringEnterPress()
  clientTable = $('#clientListTable').dataTable
    sDom: "Rlrtp"
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: '/dash_bw.json' + queryParams.search + "&dataType=src"
    bDeferRender: true
    bStateSave: false
    sScrollX: "100%"
    bScrollCollapse: true    
    aoColumns: [
                   { mData: "key", bSortable: false}, 
                   { mData: "sent", sClass: "right"},
                   { mData: "recd", sClass: "right"},
                   { mData: "total", sClass: "right"}
               ]
  #
  # NOTE: Sorting/Searching is NOT possible within the client datatable since the key can be macid/username/ip_address.
  # Username/ip_Address is looked up after getting all the BW stat records. SQL JOIN is very very costly here and hence this is like this.
  # Given the above, filtering the database records on username/ipaddress is complicated and best avoided.
  #            
  #clientTable.fnSetFilteringEnterPress()
  $("#graphBox .btn-minimize").click (e) ->
    if !$("#bw_graph_canvas").is(":visible")
      $("#graphLoadingIndicator").show()
      $.ajax '/dash_bw.json' + queryParams.search,
        dataType: 'json'
        type: 'GET'
        data: {authenticity_token: AUTH_TOKEN, dataType: 'top'}
        error: (jqXHR, textStatus, errorThrown) ->
          $("#graphLoadingIndicator").hide()
          console.log "AJAX ERROR: #{textStatus}"
        success: (data, textStatus, jqXHR) ->
          $("#graphLoadingIndicator").hide()
          #for key, value of data
          #  console.log "#{key}: #{value}"
          myLine = new RGraph.Line("bw_graph_canvas", data.values)
          myLine.Set "labels", data.labels
          myLine.Set "key.color.shape", "circle"
          myLine.Set "key.position", "graph"
          myLine.Set "key", data.keys
          myLine.Set "linewidth", 5
          myLine.Set "background.grid.autofit.numvlines", data.numvlines
          myLine.Set "colors", ["red", "black", "#DDDF0D", "#7798BF", "#ABD874", "#E18D87", "#599FD9", "#F4AD7C", "#D5BBE5"]
          myLine.Set "text.color", "#333"
          myLine.Set "text.font", "Arial"
          myLine.Set "background.grid.autofit", true
          myLine.Set "shadow", true
          myLine.Set "shadow.color", "rgba(20,20,20,0.3)"
          myLine.Set "shadow.blur", 10
          myLine.Set "shadow.offsetx", 0
          myLine.Set "shadow.offsety", 0
          myLine.Set "background.grid.border", true
          myLine.Set "axis.color", "#666"
          myLine.Set "text.color", "#666"
          myLine.Set "key.interactive", true
          myLine.Set "spline", true
          myLine.Set "title", data.title
          myLine.Set "gutter.left", 100
          myLine.Set "gutter.right", 40
          myLine.Set "tickmarks", "circle"
          myLine.Set "numxticks", 0
          myLine.Set "numyticks", 0
          #
          #Use the Trace animation to show the chart
          #
          if RGraph.isOld() or (Array.max(myLine.data_arr) < 5)
            # IE7/8 don't support shadow blur, so set custom shadow properties
            myLine.Set "shadow.offsetx", 3
            myLine.Set "shadow.offsety", 3
            myLine.Set "shadow.color", "#aaa"
            myLine.Draw()
          else
            #RGraph.Effects.Line.jQuery.UnfoldFromCenterTrace(myLine, {'duration': 1000});
            myLine.Draw()