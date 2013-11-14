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
      if (typeof pgConfig.httpproxy != 'undefined') && (pgConfig.httpproxy.enabled== 'true')
         $('#httpProxyFlag').parent().toggleClass('checked')
         $('#httpProxyIP').val(pgConfig.httpproxy.ip)
         $('#httpProxyPort').val(pgConfig.httpproxy.port)
         $('#httpProxy').show()
      $('#dtiThreshold').val(pgConfig.DTIThreshold)
      $('#loggingLevel').val(pgConfig.logmask).trigger('liszt:updated')
      #
      # Integrations Tab
      #
      if (typeof pgConfig.easAuthorizationEnabled != 'undefined') && (pgConfig.easAuthorizationEnabled != '0')
         $('#enableEASFlag').parent().toggleClass('checked')
      if (typeof pgConfig.enableMDMInterface != 'undefined') && (pgConfig.enableMDMInterface != '0')
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
  $('.firstNetworkBtn').click ->
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
  true 