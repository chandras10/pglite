# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  oTable = $('#devices').dataTable
    sDom: "RTC<'row-fluid'<'span2'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>" #'Clfrtip'
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: $('#devices').data('source')
    bDeferRender: true
    bStateSave: false
    sScrollX: "100%"
    bScrollCollapse: true
    aoColumnDefs: [{bVisible: false, bSearchable: false, aTargets: [-1]}] # Hide Parent device column
    oColVis: { aiExclude: [ 0, 16 ], bRestore: true}
    oTableTools: {
      sRowSelect: "multi", aButtons: ["select_all", "select_none", {sExtends: "text", sButtonText: "Authorize"}]
    }
    aoColumns: [
                   { mData: "macid"},
                   { mData: "username"},
                   { mData: "groupname"},
                   { mData: "location"},
                   { mData: "devicetype"},
                   { mData: "operatingsystem"},
                   { mData: "osversion"},
                   { mData: "deviceclass"},
                   { mData: "jailbroken"},
                   { mData: "dvi"},
                   { mData: "ipaddr"},
                   { mData: "created_at"},
                   { mData: "updated_at"},
                   { mData: "auth_source"},
                   { mData: "devicename"},
                   { mData: "vendorname"},
                   { mData: "parentmacid"}
                 ]      

  $('#ToolTables_devices_2').click ->
     oTT = TableTools.fnGetInstance('devices')
     anSelected = oTT.fnGetSelected()
     devices = []
     for device in anSelected
       devices.push device.id
     $.ajax '/deviceinfos/authorize' ,
       dataType: 'json'
       type: 'POST'
       data: { _method: 'PUT', authenticity_token: AUTH_TOKEN, ids: devices}
       error: (jqXHR, textStatus, errorThrown) ->
         alert("AJAX ERROR: #{textStatus}")
       success: (data, textStatus, jqXHR) ->
         oTable.fnDraw()
