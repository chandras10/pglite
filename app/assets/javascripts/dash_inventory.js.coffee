GetAssetCount = ->
  $('.assetCount #loading-indicator').show()
  $('#inventoryAssetCount').hide()
  $.ajax '/dash_inventory/assetCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('.assetCount #loading-indicator').hide()
      alert("AJAX ERROR: Session might have expired. #{textStatus}")
    success: (data, textStatus, jqXHR) ->
      $('.assetCount #loading-indicator').hide()
      $('#inventoryAssetCount').show()
      $('#inventoryAssetCount').text(data)

GetSnortAlertCount = ->
  $('.alertCount #loading-indicator').show()
  $('#inventoryAlertCount').hide()
  $.ajax '/dash_inventory/alertCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('.alertCount #loading-indicator').hide()
      alert("AJAX ERROR: Session might have expired. #{textStatus}")
    success: (data, textStatus, jqXHR) ->
      $('.alertCount #loading-indicator').hide()
      $('#inventoryAlertCount').show()
      $('#inventoryAlertCount').text(data)

GetVulnCount = ->
  $('.vulnCount #loading-indicator').show()
  $('#inventoryVulnCount').hide()
  $.ajax '/dash_inventory/vulnCount.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      $('.vulnCount #loading-indicator').hide()
      alert("AJAX ERROR: Session might have expired. #{textStatus}")
    success: (data, textStatus, jqXHR) ->
      $('.vulnCount #loading-indicator').hide()
      $('#inventoryVulnCount').show()
      $('#inventoryVulnCount').text(data)

jQuery ->
  GetAssetCount()
  GetSnortAlertCount()
  GetVulnCount()
