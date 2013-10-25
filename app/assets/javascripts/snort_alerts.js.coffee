# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  #
  # Grab the query string and append it to the Ajax source below
  #
  url = window.location.href
  a = $('<a>', { href: url})[0]
  
  dataTableOpts = "RC<'row-fluid'<'span2'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"

  oTable = $('#snortAlerts').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/tbl_snort.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
    aoColumns: [
                   { mData: "snortID"},
                   { mData: "timestamp"},
                   { mData: "message"},
                   { mData: "priority"},
                   { mData: "protocol"},
                   { mData: "source"},
                   { mData: "destination"},
                   { mData: "srcmac"},
                   { mData: "dstmac"}
                 ]      

  $('.ColVis_MasterButton').removeClass('ColVis_Button').addClass('DTTT_button')