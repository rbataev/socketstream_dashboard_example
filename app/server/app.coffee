# Server-side Code

exports.actions =

  transmit: (data, cb) ->
    SS.publish.broadcast 'transmission', data
    cb data

  saveSortOrder: (data, cb) ->
    sortOrder = data.sortOrder[9..].split('&widget[]=')
    SortOrder.findOne {profile: data.profile}, (err, doc) ->
      if !doc
        doc = new SortOrder {profile: data.profile, sortOrder: sortOrder}
      else
        doc.sortOrder = sortOrder
      doc.save (err, doc) -> cb !err

  createWidget: (data, cb) ->
    widget = new Widget data
    widget.save (err,doc) ->
      SS.publish.broadcast 'addWidget', doc if !err
      cb if !err then doc else false

  getWidgets: (profile, cb) ->
    SortOrder.findOne {profile: profile}, (err, sortOrder) ->
      query = if profile != "all" then {profile: {$in: profile.split('%20')}} else {}
      Widget.find query, (err, docs) -> cb if sortOrder then sortWidgets docs, sortOrder.sortOrder else docs

  updateWidget: (data, cb) ->
    Widget.findById data._id, (err, doc) ->
      if !doc
        cb false
      else
        for key,value of data
          doc[key] = value unless key is '_id'
        doc.save (err) ->
          SS.publish.broadcast 'updateWidget', doc if !err
          cb if !err then doc else false

  deleteWidget: (id, cb) ->
    Widget.findById id, (err, doc) ->
      doc.remove (err) ->
        SS.publish.broadcast 'removeWidget', id if !err
        cb if !err then true else false

sortWidgets = (widgets, sortOrder) ->
  find = (id) ->
    found = (w for w in widgets when w._id.toString() == id)
    if found.length > 0 then found[0] else null
  t = (find id for id in sortOrder)
  t1 = (w for w in t when w != null)
  t1.concat(w for w in widgets when t1.indexOf(w) == -1)
