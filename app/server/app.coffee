# Server-side Code

exports.actions =
  
  # Required by the HTTP API
  transmit: (data, cb) ->
    SS.publish.broadcast 'transmission', data
    cb data
