# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
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
#   $("#alertConfig .btn-primary").click ->
#        dict = $("#alertsConfigTree").dynatree("getTree").toDict()
#        for classDef in dict
#           if (classDef.children)?           
#              for c in classDef.children
#                if !c.select
#                   disabledAlerts.push c.id
#                else
#                   activateAlerts.push c.id
#        $.post '/settings/alerts',
#           disableids: disabledAlerts.toString(),
#           activeids: activateAlerts.toString()
#
   true