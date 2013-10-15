jQuery ->
   $('#loading-indicator').hide()
   $('#loading-indicator').ajaxStart ->
       $('.hoverShow').hide()
       $(this).show()
   $('#loading-indicator').ajaxStop ->
       $(this).hide()
       $('.hoverShow').show()

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

           $.ajax '/dash_bw_country.json?sEcho=1' ,
                dataType: 'json'
                type: 'GET'
                data: {authenticity_token: AUTH_TOKEN, reportTime: $('#reportTime').val(), country: code.toUpperCase()}
                error: (jqXHR, textStatus, errorThrown) ->
                  alert("AJAX ERROR: #{textStatus}")
                success: (data, textStatus, jqXHR) ->
                  totalBW = uploadBW = downloadBW = 0
                  if data
                     $('#serverCount').text(data.length)

                     for line in data
                       totalBW    += parseInt(line.total, 10)
                       uploadBW   += parseInt(line.upload, 10)
                       downloadBW += parseInt(line.download, 10)
                     $('#uploadSize').text(formatNumber(uploadBW))
                     $('#downloadSize').text(formatNumber(downloadBW))
                     $('#totalSize').text(formatNumber(totalBW))