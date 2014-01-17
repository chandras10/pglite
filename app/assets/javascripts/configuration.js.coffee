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
  helpText['aclPort'] = 
    title: 'BYOD Port'
    text: "Port through which BYODs get into the network."

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
         #
         # TODO: If we are supporting a bunch of MDM vendors, then we should save the particular MDM vendor selected in the PG config file. 
         # For now, we have only Maas360, so MDM is enabled, then just read the Maas360 plugin parameters and display...
         #
         maas360Config = data.maas360
         if (typeof maas360Config isnt "undefined")
            $('#mdmVendor').val('maas360').trigger('liszt:updated').change()
            $('#maas360 #rootURL').val(maas360Config.ROOT_WS_URL)
            $('#maas360 #billingID').val(maas360Config.BILLING_ID)
            $('#maas360 #platformID').val(maas360Config.PLATFORM_ID)   
            $('#maas360 #appID').val(maas360Config.APP_ID)    
            $('#maas360 #appVer').val(maas360Config.APP_VERSION)                  
            $('#maas360 #appAccessKey').val(maas360Config.APP_ACCESS_KEY)
            $('#maas360 #adminUsername').val(maas360Config.MAAS_ADMIN_USERNAME)
            $('#maas360 #adminPassword').val(maas360Config.MAAS_ADMIN_PASSWORD)         
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
      #
      # Cisco ACL Tab
      #
      $('#aclPortHelp').attr('data-original-title', helpText['aclPort'].title)
      $('#aclPortHelp').attr('data-content', helpText['aclPort'].text)      
      ciscoACL = data.ciscoACL
      if (typeof ciscoACL isnt "undefined")
         $('#connectionMode').val(ciscoACL.mode.toLowerCase()).trigger('liszt:updated')
         $('#switchIP').val(ciscoACL.ip)
         $('#aclPort').val(ciscoACL.port)
         $('#aclNumber').val(ciscoACL.acl_no)
         $('#aclLogin').val(ciscoACL.username)
         $('#aclPassword').val(ciscoACL.password)
         $('#aclEnablePassword').val(ciscoACL.enable)

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
  # Maas360 Plugin changes
  #  
  if $('#mdmConfig').is(':visible') 
     maas360Config = data.maas360 = {}
     maas360Config.ROOT_WS_URL = $('#maas360 #rootURL').val()
     maas360Config.BILLING_ID = $('#maas360 #billingID').val()
     maas360Config.PLATFORM_ID = $('#maas360 #platformID').val()   
     maas360Config.APP_ID = $('#maas360 #appID').val()    
     maas360Config.APP_VERSION = $('#maas360 #appVer').val()                  
     maas360Config.APP_ACCESS_KEY = $('#maas360 #appAccessKey').val()
     maas360Config.MAAS_ADMIN_USERNAME = $('#maas360 #adminUsername').val()
     maas360Config.MAAS_ADMIN_PASSWORD = $('#maas360 #adminPassword').val()
  else
     maas360Config = null
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
  data = {}
  deActivateAlerts = []
  emailAlerts = []
  dict = $("#alertsConfigTree").fancytree("getTree").toDict()
  for i of dict
    alertClassDef = dict[i]
    unless typeof alertClassDef.children is "undefined"
      for j of alertClassDef.children
        c = alertClassDef.children[j]
        unless c.data.OTHER is "undefined"
          if c.data.OTHER[0] is false
             deActivateAlerts.push c.key
          #
          if c.data.OTHER[1] is true
             emailAlerts.push c.key
  $("#inactiveids").val deActivateAlerts.toString()
  $("#emailids").val emailAlerts.toString()
  $("#restart").val restartFlag
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

saveACLConfig = (restartFlag) ->
  data = {}
  ciscoACL = data.ciscoACL = {}
  ciscoACL.mode = $('#connectionMode').val()
  ciscoACL.ip = $('#switchIP').val()
  ciscoACL.port = $('#aclPort').val()
  ciscoACL.acl_no = $('#aclNumber').val()
  ciscoACL.username = $('#aclLogin').val()
  ciscoACL.password = $('#aclPassword').val()
  ciscoACL.enable = $('#aclEnablePassword').val()
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
  else if activeTab is 'aclConfig-tab'
    saveACLConfig(restartFlag)
  $('#SaveChangesBtn').closest('form').submit() #Explicitly submitting the form here since we just call noty() in the main SubmitBtn's routine.
  $('#dialog-modal').dialog
     resizable: false
     dialogClass: 'no-close'
     title: (if restartFlag then 'Restarting...' else 'Saving...')
     height:100
     modal: true

#
# For the 'I7 Alerts' tab, set the checkboxes for each alert to the correct state based on the database values.
#
setTreeNodeCheckBoxes = (e, data) ->
  node = data.node
  #
  # Display checkboxes only on the leaf nodes. There are two - One for Active/Inactive and another for Email...
  #
  unless typeof node.data.OTHER is "undefined"
    customData = node.data.OTHER
    $(node.tr).find('input[name="active"]').prop('checked', customData[0])
    $(node.tr).find('input[name="email"]').prop('checked', customData[1])
    if customData[0] is true # Is this alert active?
       $(node.tr).find('span.fancytree-title').removeClass('fancytree-title').addClass('activeAlert')

$('#alertsConfigTree').delegate("input[name=active]", "click", (e) ->
  node = $.ui.fancytree.getNode(e)
  $input = $(e.target)
  unless node.data.OTHER is "undefined"
    node.data.OTHER[0] = $input.is(":checked")
  e.stopPropagation() # prevent fancytree activate for this row
)

$('#alertsConfigTree').delegate("input[name=email]", "click", (e) ->
  node = $.ui.fancytree.getNode(e)
  $input = $(e.target)
  unless node.data.OTHER is "undefined"
    node.data.OTHER[1] = $input.is(":checked")
  e.stopPropagation() # prevent fancytree activate for this row
)

jQuery ->
  $('#tabs-container').tabs()
  $('#dialog-modal').hide()
  $('#httpProxy').hide()
  $('#enableAD').hide()
  $('#enableLDAPAuth').hide()
  $('input[type="password"]').change( ->
     #
     # This marks the password changes correctly. That way, this plaintext value will be encrypted in the backend.
     # Password is always filled out with the encrypted password from the disk file when shown initially.
     #
     $(this).val($(this).val() + '_CHG_')
  )
  loadContextHelp()
  loadConfiguration()
  $('input[type=checkbox]').change ->
     $(this).toggle(this.checked)
     $(this).parent().toggleClass('checked')
     sibling = $(this).closest('label').next()
     $(sibling).toggle($(this).is(':checked')) unless typeof sibling is "undefined"
  $('select').chosen({disable_search_threshold: 10})
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
  $('#enableMDMFlag').change( ->
     $('#mdmConfig').toggle($(this).is(':checked'))
  )
  $('#mdmVendor').change( ->
     $('#mdmConfig table').hide()
     selectedMDM = $(this).val()
     $('#' + selectedMDM).show()
  )
  $("#alertsConfigTree").fancytree
     extensions: ["table"]
     debugLevel: 0,
     title: "Peregrine Alerts Configuration",
     autoFocus: true,
     keyboard: true,
     persist: false,
     clickFolderMode: 3,
     imagePath: '/assets/',
     checkbox: false,
     selectMode: 2,
     table:
       indentation: 20 # indent 20px per node level
       nodeColumnIdx: 1 # render the node title into the 2nd column
     source: {
       url: '/settings/alerts.json'
     }
     renderNode: setTreeNodeCheckBoxes
     renderColumns: (e, data) ->
       node = data.node
       $tdList = $(node.tr).find(">td")
       unless typeof node.data.OTHER is "undefined" #Display checkboxes for the actual alerts and ignore the high level class rows.
         $tdList.eq(0).text(node.key).addClass("alignRight")
         # (index #1 is rendered by fancytree)
         $tdList.eq(2).html("<input type='checkbox' name='active' value='" + node.key + "'>")
         $tdList.eq(3).html("<input type='checkbox' name='email' value='" + node.key + "'>")
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
         addClass: 'btn btn-danger'
         text: 'Save & Restart'
         onClick: ($noty) ->
           $noty.close()
           saveConfiguration(true)
        ,
         addClass: 'btn btn-primary'
         text: 'Save'
         onClick: ($noty) ->
           $noty.close()
           saveConfiguration(false)
        ,
         addClass: 'btn'
         text: 'Cancel'
         onClick: ($noty) ->
           $noty.close()
       ]
      false
  $('#switchIP').parsley('validate') # Check for valid IP address (IPv4 format)      
  $('.form-horizontal').parsley
     listeners:
       onFieldError: (elem, constraints, parsleyField) ->
         $(elem).closest('.control-group').addClass('error')
         false
       onFieldSuccess: (elem, constraints, parsleyField) ->
         $(elem).closest('.control-group').removeClass('error')
         false
  true 
