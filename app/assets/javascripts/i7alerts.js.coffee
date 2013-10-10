# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  dataTableOpts = "RC<'row-fluid'<'span2'l><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
  
  oTable = $('#alerts').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: $('#alerts').data('source')
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
    aoColumns: [
                   { mData: "timestamp"},
                   { mData: "priority", bSortable: false},
                   { mData: "classname", bSortable: false},
                   { mData: "id"},
                   { mData: "proto"},
                   { mData: "srcmac"},
                   { mData: "srcip"},
                   { mData: "srcport"},
                   { mData: "dstmac"},
                   { mData: "dstip"},
                   { mData: "dstport"},
                   { mData: "pcap", bSortable: false},
                   { mData: "message"}
                 ]      

  $('.ColVis_MasterButton').removeClass('ColVis_Button').addClass('DTTT_button')