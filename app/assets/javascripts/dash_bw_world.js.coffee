jQuery ->
   $('#loading-indicator').hide()
   #
   # Grab the query string and append it to the Ajax source below
   #
   url = window.location.href
   queryParams = $('<a>', { href: url})[0]
   oTable = $('#servers').dataTable
      sDom: "Rlfrtp"
      sPaginationType: "bootstrap"
      bJQueryUI: true
      bProcessing: true
      bServerSide: true
      sAjaxSource: '/dash_bw_country_details' + queryParams.search
      fnServerParams: (aoData) ->
        aoData.push
          name: "country"
          value: $('#countryCode').val()
      bDeferRender: true
      bStateSave: true
      sScrollX: "100%"
      bScrollCollapse: true
      aoColumns: [
                   { mData: "server"},
                   { mData: "port", sClass: "right"},
                   { mData: "upload", sClass: "right"},
                   { mData: "download", sClass: "right"},
                   { mData: "total", sClass: "right"}
                 ]             
   $('#vmap').vectorMap 
         map: 'world_en'
         backgroundColor: null
         borderOpacity: 0.7
         color: '#ffffff'
         hoverOpacity: 0.7
         selectedColor: '#666666'
         enableZoom: true
         showTooltip: true
         values: mapData
         scaleColors: ['#C8EEFF', '#006491']
         normalizeFunction: 'polynomial',
         onRegionClick: (event, code, region) ->
           $('#countryDetails .box-header').text(region)
           $('#countryCode').val(code.toUpperCase())
           $('.hoverShow').hide()
           $('#loading-indicator').show()
           $('#countryFlag').attr('src', '/assets/flags_iso/128/'+code+'.png')
           $('#countryFlag').attr('alt', region)
           $.ajax '/dash_bw_country.json' + queryParams.search ,
                dataType: 'json'
                type: 'GET'
                data: {authenticity_token: AUTH_TOKEN, country: code.toUpperCase()}
                error: (jqXHR, textStatus, errorThrown) ->
                  $('#loading-indicator').hide()
                  alert("AJAX ERROR: #{textStatus}")
                success: (data, textStatus, jqXHR) ->
                  servers = totalBW = uploadBW = downloadBW = 0
                  if data && data[0].total != null
                     totalBW    += parseInt(data[0].total, 10)
                     uploadBW   += parseInt(data[0].upload, 10)
                     downloadBW += parseInt(data[0].download, 10)
                     servers    += parseInt(data[0].servercount, 10)
                  $('#serverCount').text(servers)
                  $('#uploadSize').text(formatNumber(uploadBW))
                  $('#downloadSize').text(formatNumber(downloadBW))
                  $('#totalSize').text(formatNumber(totalBW))
                  $('#loading-indicator').hide()
                  $('.hoverShow').show()
                  oTable.fnDraw()
