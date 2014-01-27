# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  #
  # Grab the query string and append it to the Ajax source below
  #
  url = window.location.href
  a = $('<a>', { href: url})[0]
  
  #dataTableOpts = "R<'row-fluid'r>t<'row-fluid'<'span10'p>>"
  dataTableOpts = "Rrtip"

  oI7AlertTable = $('#i7Alerts').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/device_details/i7alerts.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
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
                   { mData: "id"},
                   { mData: "priority"},
                   { mData: "type"},
                   { mData: "message"},
                   { mData: "count"}
                 ]      

  oSnortAlertTable = $('#snortAlerts').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/device_details/snortalerts.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
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
                   { mData: "id"},
                   { mData: "priority"},
                   { mData: "message"},
                   { mData: "count"}
                 ]      

  oVulnTable = $('#deviceVulns').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/device_details/vulnerabilities.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
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
                   { mData: "id"},
                   { mData: "score"},
                   { mData: "message"},
                   { mData: "count"}
                 ]      

  oAppTable = $('#deviceApps').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/device_details/apps.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
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
                   { mData: "name"},
                   { mData: "version"}
                 ]      

  oAppTable = $('#deviceBwUsage').dataTable
    sDom: dataTableOpts
    sPaginationType: "bootstrap"
    bJQueryUI: true
    bProcessing: true
    bServerSide: true
    sAjaxSource: "/device_details/bandwidth.json" + a.search
    bDeferRender: true
    bStateSave: true
    sScrollX: "100%"
    bScrollCollapse: true
    oColVis: { bRestore: true}
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
                   { mData: "server"},
                   { mData: "port"},
                   { mData: "download"},
                   { mData: "upload"},
                   { mData: "total"}
                 ]      