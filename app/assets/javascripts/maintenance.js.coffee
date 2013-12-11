# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
createButton = (state, processName) ->
  if bAdminUser is 'false'
     '<td></td>'
  else
     if state is true
       btnLabel = '<i class="icon-stop"></i> Stop'
       btnClass = 'btn-danger'
     else
       btnLabel = '<i class="icon-play"></i> Start'
       btnClass = 'btn-primary'
     '<td><div id="' + processName + '_loading" style="display: none;"><img src="/assets/peregrine-loader.gif" alt="Peregrine-loader"></div>' +
     '    <button class="btn serviceBtn ' + btnClass + '" id="' + processName + '">' + btnLabel + '</button></td>'

updateProcStates = ->
  $.ajax '/maintenance/healthcheck',
    type: 'GET'
    dataType: 'json'
    success: (data, textStatus, jqXHR) ->
      tblContent = ""
      for processName, details of data
        tblContent += '<tr><td>' + details[0] + '</td>'
        tblContent += '<td>' + details[2] + '</td>'
        tblContent += createButton(details[1], processName)
        tblContent += '</tr>'
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
    btnID = $(this).attr('id')
    btnText = $(this).text()
    $(this).hide(); $('#' + btnID + '_loading').show()
    $.ajax '/maintenance/updateprocstate',
      dataType: 'json'
      type: 'POST'
      data: {authenticity_token: AUTH_TOKEN, service_name: btnID}
      success: (data, textStatus, jqXHR) ->
        $('#' + btnID + '_loading').hide(); $('#' + btnID).show()
        $('#' + btnID).closest('tr').find('td').eq(1).text(data[1])
        if data[0] is true
          $('#' + btnID).closest('tr').find('td').eq(2).replaceWith(createButton((btnText is ' Start'), btnID))
  )

