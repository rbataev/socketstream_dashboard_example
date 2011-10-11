# Note: SocketStream doesn't support models officially yet, but you can simulate basic CRUD as show below
# Install mongoose by typing 'npm install' in this directory
# Then make sure you're running MongoDB locally. Mongoose will create the schema for you

Widgets = new Schema # defined in /config/db.coffee
  title  : String
  html   : String
  css    : String
  coffee : String
  json   : String

Widget = mongoose.model 'Widget', Widgets

exports.actions =
      
  create: (data, cb) ->
    widget = new Widget data
    widget.save (err,doc) -> 
      SS.publish.broadcast 'addWidget', doc if !err
      cb if !err then doc else false
  
  findAll: (cb) ->
    Widget.find {}, (err, docs) -> cb docs 
    
  update: (data, cb) ->
    Widget.findById data._id, (err, doc) ->
      if !doc
        cb false
      else 
        for key,value of data
          doc[key] = value unless key is '_id'
        doc.save (err) -> 
          SS.publish.broadcast 'updateWidget', doc if !err
          cb if !err then doc else false
          
  delete: (id, cb) ->
    Widget.findById id, (err, doc) ->
      doc.remove (err) ->
        SS.publish.broadcast 'removeWidget', id if !err
        cb if !err then true else false