# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('#auth_device_dialog_placeholder').hide()
  #
  # Allow only Administrative users to change device attributes. Right now, we are using the datatable's TableTool button array
  # to let the user modify the attributes. Hence we will add the 'T' option to sDom parameter only for admins.
  # This means other users will not see any buttons and hence cannot modify anything at all!
  #
  if bAdminUser == "true"
     dataTableOpts = "RTC<'row-fluid'<'span2'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
  else
     dataTableOpts = "RC<'row-fluid'<'span2'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
  
  oTable = $('#devices').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: $('#devices').data('source')
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    aoColumnDefs: [{bVisible: false, bSearchable: false, aTargets: [-1]}] # Hide Parent device column
    oColVis: { bRestore: true}
    oTableTools: {
      sRowSelect: "multi", aButtons: ["select_all", "select_none", {sExtends: "text", sButtonText: "Authorize"}]
    }
    fnServerData: (sSource, aoData, fnCallback) ->
      $.ajax(
        dataType: 'json'
        type: 'GET'
        url: sSource
        data: aoData
        success: fnCallback
        error: handleDatatablesAjaxError
      )
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
                   { mData: "dti"},
                   { mData: "ipaddr"},
                   { mData: "created_at"},
                   { mData: "updated_at"},
                   { mData: "auth_source"},
                   { mData: "devicename"},
                   { mData: "vendorname"},
                   { mData: "parentmacid"}
                 ]

  $('.ColVis_MasterButton').removeClass('ColVis_Button').addClass('DTTT_button')

  $('#ToolTables_devices_2').click ->
     oTT = TableTools.fnGetInstance('devices')
     anSelected = oTT.fnGetSelected()
     if anSelected.length > 0
        $('#auth_device_dialog_placeholder').dialog
          resizable: false
          modal: true
          buttons:
            "Cancel": ->
              jQuery(this).dialog "close"
            "OK": ->
              auth_src = $('#select_auth_source').val()
              jQuery(this).dialog "close"
              devices = []
              for device in anSelected
                devices.push device.id
              $.ajax '/deviceinfos/authorize' ,
                dataType: 'json'
                type: 'POST'
                data: { _method: 'PUT', authenticity_token: AUTH_TOKEN, auth_type: auth_src, ids: devices}
                error: (jqXHR, textStatus, errorThrown) ->
                  console.log "AJAX ERROR: #{textStatus}"
                success: (data, textStatus, jqXHR) ->
                  oTable.fnDraw()
     else
       noty
         text: 'Please select one or more devices to change the authorization.'
         type: 'information'

