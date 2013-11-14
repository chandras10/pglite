jQuery ->
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
  $('#firstHomeNet').click ->
     rowElem = $(this).closest('tr')
     newHomeNet = rowElem.clone(true)
     $('.homeNetAddButton', newHomeNet).text('Remove')
     $('.homeNetAddButton', newHomeNet).click ->
       $(this).closest('tr').remove()
     $(newHomeNet).appendTo(rowElem.parent())
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