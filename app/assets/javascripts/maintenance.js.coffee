# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

updateProcStates = ->
  $.ajax '/maintenance/healthcheck',
    type: 'GET'
    dataType: 'json'
    success: (data, textStatus, jqXHR) ->
      tblContent = '<tr><td> Process </td><td> Status </td><td></td>';
      for processName, details of data
        if details[1] is true
           btnLabel = "Stop"
        else
           btnLabel = "Start"
        tblContent += '<tr><td>' + details[0] + '</td><td>' + details[2] + '</td>'
        if bAdminUser is 'true'
           tblContent += '<td><button class="btn btn-small btn-primary serviceBtn" id="' + processName + '">' + btnLabel + '</button></td></tr>'
        else
           tblContent += '<td></td></tr>'
      $('#processTable tbody').html(tblContent)
      true

jQuery ->
  $('#tabs-container').tabs(
     select: (event, ui) ->
       if ui.panel.id is "health-tab"
          updateProcStates()
  )
  $('#newLicensePanel').hide()
  $('#showNewLicenseCtrlsBtn').click( (e)->
    $('#newLicensePanel').show()
    e.preventDefault()
  )
  $('.serviceBtn').live('click', ->
    # Set the btn id that was clicked. This is mapped to the backend process to started/stopped
    $('#service_name').val($(this).attr('id'))
  )

