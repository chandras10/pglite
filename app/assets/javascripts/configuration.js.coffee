ipv4_pattern = new RegExp("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/(?:[0-9]|1[0-9]|2[0-9]|3[0-2])$") 

isBlank = (str) ->
  (!str || /^\s*$/.test(str))

loadConfiguration = ->
  $.ajax '/settings.json',
    dataType: 'json'
    type: 'GET'
    data: {authenticity_token: AUTH_TOKEN}
    error: (jqXHR, textStatus, errorThrown) ->
      # do something
    success: (data, textStatus, jqXHR) ->
      pgConfig = data.pgguard
      #
      # Application Tab
      #
      $('#interface').val(pgConfig.interface)
      $('#probeInterval').val(pgConfig.probeInterval)
      $('#updateInterval').val(pgConfig.statUpdateInterval)
      if (typeof pgConfig.httpproxy != 'undefined') && (pgConfig.httpproxy.enabled == true)
         $('#httpProxyFlag').parent().toggleClass('checked')
         $('#httpProxyIP').val(pgConfig.httpproxy.ip)
         $('#httpProxyPort').val(pgConfig.httpproxy.port)
         $('#httpProxy').show()
      $('#dtiThreshold').val(pgConfig.DTIThreshold)
      $('#loggingLevel').val(pgConfig.logmask).trigger('liszt:updated')
      #
      # Integrations Tab
      #
      if (typeof pgConfig.easAuthorizationEnabled != 'undefined') && (pgConfig.easAuthorizationEnabled != false)
         $('#enableEASFlag').parent().toggleClass('checked')
      if (typeof pgConfig.enableMDMInterface != 'undefined') && (pgConfig.enableMDMInterface != false)
         $('#enableMDMFlag').parent().toggleClass('checked')
      if (typeof pgConfig.authentication != 'undefined')
         if (typeof pgConfig.authentication.ldap)
            $('#enableLDAPAuthFlag').parent().toggleClass('checked')
            $('#ldapServerIP').val(pgConfig.authentication.ldap.server)
            $('#ldapServerPort').val(pgConfig.authentication.ldap.port)
            $('#ldapBaseDN').val(pgConfig.authentication.ldap.baseDN)
            $('#ldapDomain').val(pgConfig.authentication.ldap.domain)
            $('#enableLDAPAuth').show()
      #
      # Files Tab
      #
      $('#licenseFile').val(pgConfig['licensefile'])
      $('#databasePath').val(pgConfig.dbpath)
      $('#deviceFingerprintFile').val(pgConfig.fingerprintdb)
      $('#deviceVendorFile').val(pgConfig.vendorfile)
      $('#policyFile').val(pgConfig.policy)

saveApplicationConfig = ->
  data = {}
  pgConfig = data.pgguard = {}
  pgConfig.interface = $('#interface').val()
  pgConfig.probeInterval = $('#probeInterval').val()
  pgConfig.statUpdateInterval = $('#updateInterval').val()
  pgConfig.httpproxy = {}
  pgConfig.httpproxy.enabled = ($('#httpProxyFlag').parent().attr('class') == 'checked')
  pgConfig.httpproxy.ip = $('#httpProxyIP').val()
  pgConfig.httpproxy.port = $('#httpProxyPort').val()
  pgConfig.DTIThreshold = $('#dtiThreshold').val()
  pgConfig.logmask = $('#loggingLevel').val()
  pgConfig.homeNets = ''
  $('input[type=text]', '#homeNets').each( ->
     homeNet = $(this).val().replace(/\s/g, "") 
     if (!isBlank(homeNet) && ipv4_pattern.test(homeNet))
           pgConfig.homeNets += homeNet + ';'
  )
  $('#tabParms').val(JSON.stringify(data))

savePluginConfig = ->
  data = {}
  pgConfig = data.pgguard = {}
  pgConfig.easAuthorizationEnabled = ($('#enableEASFlag').parent().attr('class') == 'checked')
  pgConfig.enableMDMInterface = ($('#enableMDMFlag').parent().attr('class') == 'checked')
  $('#tabParms').val(JSON.stringify(data))

jQuery ->
  loadConfiguration()
  $('#httpProxy').hide()
  $('#enableAD').hide()
  $('#enableLDAPAuth').hide()
  $('input[type=checkbox]').change ->
     $(this).parent().toggleClass('checked')
  $('#httpProxyFlag').change ->
     $('#httpProxy').toggle(this.checked)
  $('#loggingLevel').chosen({disable_search_threshold: 10})
  $('#enableADFlag').change ->
     $('#enableAD').toggle(this.checked)
  $('#enableLDAPAuthFlag').change ->
     $('#enableLDAPAuth').toggle(this.checked)
  $('.firstHomeNetworkBtn').click ->
     rowElem = $(this).closest('tr')
     newHomeNet = rowElem.clone(true)
     $(newHomeNet).appendTo(rowElem.parent())
  $('.homeNetworkBtn').text('Remove')
  $('.homeNetworkBtn').click ->
     $(this).closest('tr').remove()
  $("#alertsConfigTree").dynatree
     debugLevel: 0,
     title: "Peregrine Alerts Configuration",
     autoFocus: true,
     keyboard: true,
     persist: false,
     clickFolderMode: 3,
     imagePath: '/assets/dynatree/',
     checkbox: true,
     selectMode: 2,
     initAjax: {
       url: '/settings/alerts.json'
     }
  $('#SaveChangesBtn').click ->
     activeTab = $('#TabList').find('.tab-pane.active').attr('id')
     if activeTab is 'peregrineConfig-tab'
        saveApplicationConfig()
     else if activeTab is 'pluginConfig-tab'
        savePluginConfig()
  true 