Geti7AlertCount = ->
  $('#i7AlertCount #loading-indicator').show()
  $('#i7AlertCount .counter').hide()
  $.ajax '/dash_inventory/i7AlertCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('#i7AlertCount #loading-indicator').hide()
    success: (data, textStatus, jqXHR) ->
      $('#i7AlertCount #loading-indicator').hide()
      $('#i7AlertCount .counter').text(data).show()

GetSnortAlertCount = ->
  $('#snortAlertCount #loading-indicator').show()
  $('#snortAlertCount .counter').hide()
  $.ajax '/dash_inventory/snortAlertCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('#snortAlertCount #loading-indicator').hide()
    success: (data, textStatus, jqXHR) ->
      $('#snortAlertCount #loading-indicator').hide()
      $('#snortAlertCount .counter').text(data).show()

GetVulnCount = ->
  $('#vulnCount #loading-indicator').show()
  $('#vulnCount .counter').hide()
  $.ajax '/dash_inventory/vulnCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('#vulnCount #loading-indicator').hide()
    success: (data, textStatus, jqXHR) ->
      $('#vulnCount #loading-indicator').hide()
      $('#vulnCount .counter').text(data).show()

CreateAlertNotification = (container, type, text) ->
  notyTypes = ['notification', 'error', 'warning', 'information', 'alert', 'success' ]
  iconTypes = ['icon-orange icon-comment',
               'icon-white icon-cancel',
               'icon-red icon-alert',
               'icon-blue icon-info',
               'icon-green icon-star-off',
               'icon-white icon-flag']
  n = $(container).noty(
    text: text
    type: notyTypes[type]
    dismissQueue: true
    layout: "topCenter"
    template: '<div title="Priority: ' + type + '" style="font-size: 13px; line-height: 16px; padding: 8px 10px 9px; width: auto; position: relative;"><span class="icon32 ' + iconTypes[type] + '" style="width: 2.25em" /> <span class="noty_text"></span></div>',
    theme: "defaultTheme"
    force: true
    maxVisible: 5
    animation:
      open:
        height: "toggle"

      close:
        height: "toggle"

      easing: "swing"
      speed: 500 # opening & closing animation speed
  )

GetPeregrineAlerts = ->
  $('#peregrineAlertsContainer #loading-indicator').show()
  $.ajax '/dash_inventory/latesti7Alerts.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('#peregrineAlertsContainer #loading-indicator').hide()
    success: (data, textStatus, jqXHR) ->
      $('#peregrineAlertsContainer #loading-indicator').hide()
      for alert in data
        alertText = '<b>' + alert.timestamp + '</b><br>' + alert.description + '<br><b>Device: </b>' + alert.srcmac
        CreateAlertNotification('#peregrineAlertsContainer', alert.priority, alertText)

jQuery ->
  Geti7AlertCount()
  GetSnortAlertCount()
  GetVulnCount()
  GetPeregrineAlerts()
