ipv4_pattern = new RegExp("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/(?:[0-9]|1[0-9]|2[0-9]|3[0-2])$") 

isBlank = (str) ->
  (!str || /^\s*$/.test(str))

helpText = {}
loadContextHelp = ->
  helpText['homeNet'] =
    title: 'Home Network'
    text: "This is the network(s) that is accessed from the BYODs. IP addresses belonging to this network(s) are labelled as 'internal' for 
           purpose of statistical/security analysis. IPs not in this range are considered 
           'external' or part of the WAN."
  helpText['byodNet'] =
    title: 'BYOD Network'
    text: "BYODs connecting to the wireless network will be assigned IP from this address pool. 
           Peregrine will mainly monitor the traffic from/to this network. "

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
      $('#homeNetHelp').attr('data-original-title', helpText['homeNet'].title)
      $('#homeNetHelp').attr('data-content', helpText['homeNet'].text)      
      $('#byodNetHelp').attr('data-original-title', helpText['byodNet'].title)
      $('#byodNetHelp').attr('data-content', helpText['byodNet'].text)      
      $('#interface').val(pgConfig.interface)
      if (typeof pgConfig.httpproxy isnt "undefined") and (pgConfig.httpproxy.enabled is "true")
         $('#httpProxyFlag').parent().toggleClass('checked')
         $('#httpProxyFlag').prop('checked', true)
         $('#httpProxyIP').val(pgConfig.httpproxy.ip)
         $('#httpProxyPort').val(pgConfig.httpproxy.port)
         $('#httpProxy').show()
      $('#dtiThreshold').val(pgConfig.DTIThreshold)
      $('#loggingLevel').val(pgConfig.logmask).trigger('liszt:updated')
      #
      # Integrations Tab
      #
      if (typeof pgConfig.easAuthorizationEnabled isnt "undefined") and (pgConfig.easAuthorizationEnabled is "true")      
         $('#enableEASFlag').prop('checked', true)
         $('#enableEASFlag').parent().toggleClass('checked')
      if (typeof pgConfig.enableMDMInterface isnt "undefined") and (pgConfig.enableMDMInterface is "true")      
         $('#enableMDMFlag').prop('checked', true)
         $('#enableMDMFlag').parent().toggleClass('checked')         
      if (typeof pgConfig.authentication isnt "undefined" and pgConfig.authentication?)
         if (typeof pgConfig.authentication.ldap isnt "undefined")
            $('#enableLDAPAuthFlag').parent().toggleClass('checked')
            $('#enableLDAPAuthFlag').prop('checked', true)
            $('#ldapServerIP').val(pgConfig.authentication.ldap.ip)
            $('#ldapServerPort').val(pgConfig.authentication.ldap.port)
            $('#ldapBaseDN').val(pgConfig.authentication.ldap.base)
            $('#ldapDomain').val(pgConfig.authentication.ldap.domain)
            $('#enableLDAPAuth').show()
      adPlugin = data.ad_plugin
      if (typeof adPlugin isnt "undefined")
         $('#enableADFlag').parent().toggleClass('checked')
         $('#enableADFlag').prop('checked', true)
         $('#activeDirectoryServerIP').val(adPlugin.ip)
         $('#activeDirectoryUser').val(adPlugin.username)
         $('#activeDirectoryPassword').val(adPlugin.password)
         $('#activeDirectorySSID').val(adPlugin.ssid)
         $('#activeDirectoryPingInterval').val(adPlugin.polltime)
         $('#enableAD').show()
      #
      # Email Tab
      #
      if (typeof pgConfig.email isnt "undefined") and (typeof pgConfig.email.smtp isnt "undefined")
         smtpSettings = pgConfig.email.smtp
         $('#smtpServer').val(smtpSettings.ip)
         $('#smtpPort').val(smtpSettings.port)
         $('#smtpLogin').val(smtpSettings.login)
         $('#smtpPassword').val(smtpSettings.password)
         $('#emailTo').val(pgConfig.email.to)
         $('#emailCc').val(pgConfig.email.cc)

saveApplicationConfig = (restartFlag) ->
  data = {}
  pgConfig = data.pgguard = {}
  pgConfig.interface = $('#interface').val()
  pgConfig.httpproxy = {}
  pgConfig.httpproxy.enabled = ($('#httpProxyFlag').parent().attr('class') == 'checked')
  pgConfig.httpproxy.ip = $('#httpProxyIP').val()
  pgConfig.httpproxy.port = $('#httpProxyPort').val()
  pgConfig.DTIThreshold = $('#dtiThreshold').val()
  pgConfig.logmask = $('#loggingLevel').val()
  pgConfig.homeNets = ''
  $('input[type=text]', '#homeNets').each( ->
     homeNet = $(this).val().replace(/\s/g, "") 
     if !isBlank(homeNet) && ipv4_pattern.test(homeNet)
       pgConfig.homeNets += homeNet + ';'
  )
  pgConfig.byodNets = ''
  $('input[type=text]', '#byodNets').each( ->
     byodNet = $(this).val().replace(/\s/g, "") 
     if !isBlank(byodNet) && ipv4_pattern.test(byodNet)
       pgConfig.byodNets += byodNet + ';'
  )
  data.restart = restartFlag
  $('#tabParms').val(JSON.stringify(data))

savePluginConfig = (restartFlag) ->
  data = {}
  pgConfig = data.pgguard = {}
  pgConfig.easAuthorizationEnabled = $('#enableEASFlag').parent().attr('class') == 'checked'
  pgConfig.enableMDMInterface = $('#enableMDMFlag').parent().attr('class') == 'checked'
  #
  # AD Plugin configuration
  #
  if $('#enableADFlag').is(':checked')
     adPlugin = data.ad_plugin = {}
     adPlugin.ip = $('#activeDirectoryServerIP').val()
     adPlugin.username = $('#activeDirectoryUser').val()
     adPlugin.password = $('#activeDirectoryPassword').val()
     adPlugin.ssid = $('#activeDirectorySSID').val()
     adPlugin.polltime = $('#activeDirectoryPingInterval').val()
  else
     data.ad_plugin = null
  #
  # LDAP Authentication
  #  
  if $('#enableLDAPAuthFlag').is(':checked')
     pgConfig.authentication = {}
     ldapAuth = pgConfig.authentication.ldap = {}
     ldapAuth.ip = $('#ldapServerIP').val()
     ldapAuth.port = $('#ldapServerPort').val()
     ldapAuth.base = $('#ldapBaseDN').val()
     ldapAuth.domain = $('#ldapDomain').val()
  else
     pgConfig.authentication = ''
  data.restart = restartFlag
  $('#tabParms').val(JSON.stringify(data))

saveAlerts = (restartFlag) ->
  activateAlerts = []
  disabledAlerts = []
  dict = $("#alertsConfigTree").dynatree("getTree").toDict()
  for i of dict
    classDef = dict[i]
    unless typeof classDef.children is "undefined"
      for j of classDef.children
        c = classDef.children[j]
        unless c.select
          disabledAlerts.push c.id
        else
          activateAlerts.push c.id
  $("#disableids").val disabledAlerts.toString()
  $("#activeids").val activateAlerts.toString()
  $("#alertsConfig_form").submit()

saveEmailConfig = (restartFlag) ->
  data = {}
  pgConfig = data.pgguard = {}
  pgConfig.email = {}
  smtpConfig = pgConfig.email.smtp = {}
  smtpConfig.ip = $('#smtpServer').val()
  smtpConfig.port = $('#smtpPort').val()
  smtpConfig.login = $('#smtpLogin').val()
  smtpConfig.password = $('#smtpPassword').val()
  pgConfig.email.to = $('#emailTo').val()
  pgConfig.email.cc = $('#emailCc').val()
  data.restart = restartFlag
  $('#tabParms').val(JSON.stringify(data))

saveConfiguration = (restartFlag) ->
  activeTab = $('#TabList').find('.tab-pane:visible').attr('id')
  if activeTab is 'peregrineConfig-tab'
    saveApplicationConfig(restartFlag)
  else if activeTab is 'pluginConfig-tab'
    savePluginConfig(restartFlag)
  else if activeTab is 'alertsConfig-tab'
    saveAlerts(restartFlag)
    return false # Abort form submission for this tab. The data is saved to the database instead of config files via AJAX call.
  else if activeTab is 'emailConfig-tab'
    saveEmailConfig(restartFlag)
  $('#SaveChangesBtn').closest('form').submit() #Explicitly submitting the form here since we just call noty() in the main SubmitBtn's routine.
  $('#dialog-modal').dialog
     resizable: false
     dialogClass: 'no-close'
     title: (if restartFlag then 'Restarting...' else 'Saving...')
     height:100
     modal: true

jQuery ->
  $('#tabs-container').tabs()
  $('#dialog-modal').hide()
  $('#httpProxy').hide()
  $('#enableAD').hide()
  $('#enableLDAPAuth').hide()
  loadContextHelp()
  loadConfiguration()
  $('input[type=checkbox]').change ->
     $(this).toggle(this.checked)
     $(this).parent().toggleClass('checked')
     sibling = $(this).closest('label').next()
     $(sibling).toggle($(this).is(':checked')) unless typeof sibling is "undefined"
  $('#loggingLevel').chosen({disable_search_threshold: 10})
  $('.firstHomeNetworkBtn').click ->
     rowElem = $(this).closest('tr')
     newHomeNet = rowElem.clone(false)
     $('input', newHomeNet).parsley('validate')
     $('input', newHomeNet).val('')
     $('button', newHomeNet).removeClass('firstHomeNetworkBtn').addClass('homeNetworkBtn').text('Remove')
     $(newHomeNet).appendTo(rowElem.parent())
  $('.homeNetworkBtn').text('Remove')
  $('.homeNetworkBtn').live('click', ->
     $(this).closest('tr').remove()
  )
  $('.firstByodNetworkBtn').click ->
     rowElem = $(this).closest('tr')
     newByodNet = rowElem.clone(false)
     $('input', newByodNet).parsley('validate')
     $('input', newByodNet).val('')
     $('button', newByodNet).removeClass('firstByodNetworkBtn').addClass('byodNetworkBtn').text('Remove')
     $(newByodNet).appendTo(rowElem.parent())
  $('.byodNetworkBtn').text('Remove')
  $('.byodNetworkBtn').live('click', ->
     $(this).closest('tr').remove()
  )
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
     activeTab = $('#TabList').find('.tab-pane:visible').attr('id')
     activeTabName = $('a[href="#' + activeTab + '"]').text()
     noty
       layout: 'center'
       text: "<legend>Save <b style='color: #43A1DA'> " + activeTabName + "</b> settings?</legend> Please note that only the active tab is saved. <br><br><br>"
       timeout: 0
       type: 'confirm'
       modal: true
       buttons: [
         type: 'btn btn-danger'
         text: 'Save & Restart'
         click: ($noty) ->
           $noty.close()
           saveConfiguration(true)
        ,
         type: 'btn btn-primary'
         text: 'Save'
         click: ($noty) ->
           $noty.close()
           saveConfiguration(false)
        ,
         type: 'btn'
         text: 'Cancel'
         click: ($noty) ->
           $noty.close()
       ]
      false
  $('.form-horizontal').parsley
     listeners:
       onFieldError: (elem, constraints, parsleyField) ->
         $(elem).closest('.control-group').addClass('error')
         false
       onFieldSuccess: (elem, constraints, parsleyField) ->
         $(elem).closest('.control-group').removeClass('error')
         false
  true 