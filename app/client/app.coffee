# Client-side Code

getProfile = -> window.location.pathname[1..]

saveSortOrder = -> SS.server.app.saveSortOrder
  profile: getProfile()
  sortOrder: $(this).sortable 'serialize'

exports.init = ->

  $('#overlay').live 'click', ->
    $('.dialogue').remove()
    $(@).remove()

  window.widgetModel = new Model 'Widget', ->
    @unique_key = "_id"
    @include
      bindWidgetHtmlAndCss: ->
        $("#widget_#{@attributes._id}").find('.content').html @attributes.html
        cssContainer = $('<style type="text/css"></style>')
        cssContainer.text scopeCSS @attributes.css, @attributes._id
        $('head').append cssContainer
      executeCoffee: (data) ->
        window.data = data
        CoffeeScript.run @attributes.coffee

  widgetModel.bind "add", (newObject) ->
    widgetTemplate.add newObject.attributes
    newObject.bindWidgetHtmlAndCss()

  widgetModel.bind "remove", (removedObject) ->
    widgetTemplate.findInstance(removedObject.attributes._id).animate {opacity: 0}, 1000, -> widgetTemplate.remove removedObject.attributes._id

  window.widgetTemplate   = new SmartTemplate 'widget', bindDataToCssClasses: true
  window.dialogueTemplate = new SmartTemplate 'dialogue', templateHtml: $($("#dialogs-dialog").html()),  bindDataToCssClasses: true, appendTo: $('body'), afterAdd: (object) ->
    object.hide().fadeIn('slow')
    object.draggable {handle:'.dialogue-heading'}
    object.find('.dialogue-close').click ->
      window.dialogueTemplate.remove object.attr('id')
      $('#overlay').remove()

  SS.server.app.getWidgets getProfile(), (widgets) ->
    new widgetModel(widget).save() for widget in widgets

  # Bind behaviour for creating a new widget
  $('#newWidget').click ->

    $('body').append("<div id='overlay'></div>")
    $('#overlay').hide().fadeIn()

    dialogueTemplate.add {id: 'new', 'dialogue-title': 'Create a new Widget'}
    dialogue = dialogueTemplate.findInstance('new')
    dialogue.find('.dialogue-content').html $($('#dialogs-widgetForm').html())
    dialogue.css top: "#{(document.height-dialogue.height())/2}px", left: "#{(document.width - dialogue.width())/2}px"

    $('.htmlContent textarea').val '<div class="dynamicsparkline"></div>\n<div class="value">⌛</div>'
    $('.cssContent textarea').val '.value {\n\tpadding-top: 15px;\n\tfont-size: 8em;\n\tfont-weight: bold;\n\ttext-shadow: 1px 1px 1px black;\n\ttext-align: center;\n\tcolor: white;\n}'
    $('.coffeeContent textarea').val '# Html is scoped to $("#widget_"+data.id)\n\n

criticalThreashold = 10000\n
warningThreashold = 5000\n\n

criticalColor = "rgba(255,45,0,0.8)"\n
warningColor = "rgba(255, 215, 0, 0.8)"\n
normalColor = "rgba(127, 255, 0, 0.5)"\n

$("#widget_"+data.id)\n\n

$("#widget_"+data.id).find(".value").text(data.value)\n\n

widget = $("#widget_"+data.id)\n\n

points = widget.data("points") or []\n\n

points.push(data.value)\n\n

if points.length > 30 then points.splice(0, 1)\n\n

widget.data("points", points)\n\n

color = normalColor\n
if data.value > criticalThreashold\n
    color = criticalColor\n
else if data.value > warningThreashold\n
    color = warningColor\n\n

widget.css(backgroundColor: color)\n\n
widget.find(".dynamicsparkline").sparkline(points, width: "140px", height: "70px", chartRangeMin: 0, normalRangeMin: 0, normalRangeMax: criticalThreashold , normalRangeColor: "#111")\n\n
'
    $('.jsonContent textarea').val '{value: 0.24}'

    renderLivePreview()

    $('form#widget input[name="title"]').live 'keyup', ->
        $('.demoContent').find('.title').text $('form#widget').find('input[name="title"]').val()

    $('.tab').click ->
      $('.tab').removeClass('active')
      $('.tabContent').removeClass('active')
      $(@).addClass('active')
      id = $(@).attr('id')
      $('.'+id+'Content').addClass('active')
      renderLivePreview() if id is 'demo'

    $('form#widget').submit ->
      data =
        title: $(@).find('input[name="title"]').val()
        html: $('.htmlContent textarea').val()
        css: $('.cssContent textarea').val()
        coffee: $('.coffeeContent textarea').val()
        json: $('.jsonContent textarea').val()
        profile: p for p in $(@).find('input[name="profile"]').val().split(' ') when p != ''
      if data.profile.length == 0
        alert "Enter profile"
        return false
      SS.server.app.createWidget data, (res) ->
        if res is false
          alert "Balls. Mongo doesn't like it :("
        else
          data._id = res._id
          dialogueTemplate.remove 'new'
          dialogueTemplate.add {id: 'new', 'dialogue-title': 'Test your new Widget'}
          dialogue = dialogueTemplate.findInstance('new')
          dialogue.find('.dialogue-content').html "<p>Ping this url to send data to your widget:</p><code><a href='#{buildApiUrl(data)}' target='_blank'>#{buildApiUrl(data)}</a></code>"
          dialogue.css top: "#{(document.height-dialogue.height())/2}px", left: "#{(document.width - dialogue.width())/2}px"

      false

  $('#widgets').sortable
    handle: '.title'
    stop: saveSortOrder

  SS.events.on 'transmission', (data) -> 
    w = widgetModel.find(data.id)
    w.executeCoffee data if w

  SS.events.on 'addWidget', (data) -> new widgetModel(data).save()

  SS.events.on 'removeWidget', (id) -> widgetModel.find(id).destroy()

  SS.events.on 'updateWidget', (data) ->
    widget = widgetModel.find(data._id)
    widget.attr(key,value) for key,value of data
    widget.save()
    widgetTemplate.update widgetModel.find(widget.id()).attributes
    widget.bindWidgetHtmlAndCss()

  SS.socket.on 'disconnect', ->
    $('#message').text('SocketStream server has gone down :-(')

  SS.socket.on 'connect', ->
    $('#message').text('SocketStream server is back up :-)')

  scopeCSS = (text,id) ->
    lines = text.split("\n")
    for line in lines
      text = text.replace(line, "#widget_#{id} #{line}") if line.match(/{/) isnt null
    text

  # Deletes the widget
  $('.delete').live 'click', ->
    if confirm("Do you REALLY want to delete this widget? This will permanently delete it for ALL users. Think twice.")
      id = $(@).parent().parent().attr('id').split('_')[1]
      SS.server.app.deleteWidget id, (res) ->
        if res isnt true then alert "There was an error deleting the widget"

  $('.clone').live 'click', ->
    id = $(@).parent().parent().attr('id').split('_')[1]
    widget = widgetModel.find(id)
    data =
      title: widget.attributes.title + " (clone)"
      html: widget.attributes.html
      css: widget.attributes.css
      coffee: widget.attributes.coffee
      json: widget.attributes.json
      profile: p for p in widget.attributes.profile
    SS.server.app.createWidget data, (res) ->
      if res is false
        alert "Balls. Mongo doesn't like it :("


  # Shows the configure widget dialog
  $('.config').live 'click', ->

    $('body').append("<div id='overlay'></div>")
    $('#overlay').hide().fadeIn()

    id = $(@).parent().parent().attr('id').split('_')[1]
    widget = widgetModel.find(id)
    dialogueTemplate.add {id: id, 'dialogue-title': "Edit Widget: #{widget.attributes.title}"}
    dialogue = dialogueTemplate.findInstance(id)
    dialogue.find('.dialogue-content').html $($('#dialogs-widgetForm').html())
    dialogue.find('.dialogue-content #theBoringBit').prepend "<div class='apiUrl'><b>API URL:</b> <a href='#{buildApiUrl(widget.attributes)}' target='_blank'>#{buildApiUrl(widget.attributes)}</a></div>"
    dialogue.css top: "#{(document.height-dialogue.height())/2}px", left: "#{(document.width - dialogue.width())/2}px"

    $('form#widget input[type="submit"]').val 'Save'

    $('.htmlContent textarea').val widget.attributes.html
    $('.cssContent textarea').val widget.attributes.css
    $('.coffeeContent textarea').val widget.attributes.coffee
    $('.jsonContent textarea').val widget.attributes.json
    $('form#widget').find('input[name="title"]').val widget.attributes.title
    $('form#widget').find('input[name="profile"]').val widget.attributes.profile.join ' '

    renderLivePreview()

    $('form#widget input[name="title"]').live 'keyup', ->
        $('.demoContent').find('.title').text $('form#widget').find('input[name="title"]').val()

    $('.tab').click ->
      $('.tab').removeClass('active')
      $('.tabContent').removeClass('active')
      $(@).addClass('active')
      id = $(@).attr('id')
      $('.'+id+'Content').addClass('active')
      renderLivePreview() if id is 'demo'

    # form submit
    $('form#widget').submit ->
      data =
        _id: widget.id()
        title: $(@).find('input[name="title"]').val()
        html: $('.htmlContent textarea').val()
        css: $('.cssContent textarea').val()
        coffee: $('.coffeeContent textarea').val()
        json: $(@).find('.jsonContent textarea').val()
        profile: p for p in $(@).find('input[name="profile"]').val().split(' ') when p != ''
      if data.profile.length == 0
        alert "Enter profile"
        return false
      SS.server.app.updateWidget data, (res) ->
        if res is false
          alert "Balls. Mongo doesn't like it :("
        else
          dialogueTemplate.remove widget.id()
          $('#overlay').remove()
      false

  renderLivePreview = ->
    window.data = {id:'preview'}
    html = $('.widget.template').clone().removeClass('template').attr('id','widget_preview').show()
    html.find('.title').text $('form#widget').find('input[name="title"]').val()
    html.find('.content').html $('.htmlContent textarea').val()
    $('.demoContent').html html
    $('#cssHolder').html $('.cssContent textarea').val()
    window.dataToMerge = eval("obj = #{$('.jsonContent textarea').val()}")
    data[key] = value for key,value of dataToMerge
    CoffeeScript.run $('.coffeeContent textarea').val()

  buildApiUrl = (data) ->
    string = []
    string.push "&#{key}=#{value}" for key,value of eval("obj = #{data.json}")
    "#{document.location.origin}/api/app/transmit?id=#{data._id}#{string.join('')}"
