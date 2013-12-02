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
  
  oTable = $('#alerts').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: $('#alerts').data('source') + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
    aoColumns: [
                   { mData: "timestamp"},
                   { mData: "priority", bSortable: false},
                   { mData: "alerttype", bSortable: false},
                   { mData: "id"},
                   { mData: "proto"},
                   { mData: "srcmac"},
                   { mData: "srcip"},
                   { mData: "srcport"},
                   { mData: "dstmac"},
                   { mData: "dstip"},
                   { mData: "dstport"},
                   { mData: "pcap", bSortable: false},
                   { mData: "message"}]
    fnDrawCallback: ->
      $('#alerts').dataTable().$('a[rel=popover]').popover
        trigger: 'hover'
      .hover (e) ->
        e.preventDefault()
  true

  $('.ColVis_MasterButton').removeClass('ColVis_Button').addClass('DTTT_button')

