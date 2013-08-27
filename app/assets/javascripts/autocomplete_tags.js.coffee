->
$('#accordion .objectList .username').autocomplete
   minLength: 1
   source: (request, response) ->
      $.ajax 
          url: $('#accordion .objectList .username').data('autocompleteurl')
          dataType: "json"
          data:
             uname: request.term
          success: (data) ->
             response(data)

$('#accordion .objectList .userrole').autocomplete
   minLength: 1
   source: (request, response) ->
      $.ajax 
          url: $('#accordion .objectList .userrole').data('autocompleteurl')
          dataType: "json"
          data:
             groupname: request.term
          success: (data) ->
             response(data)