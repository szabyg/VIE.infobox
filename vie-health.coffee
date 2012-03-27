# TODO 
# * Load and visualize config when an entity is loaded
# * add property title config to each portlet
# * add visualization options
debugger
Vhealth = {}
# Define Vhealth methods
this.Vhealth = _(Vhealth).extend
  lsName: "vhealthConfig"
  # uri to curie
  shortenUri: (u) ->
    try
      return @vie.namespaces.curie(u)
    catch e
      console.warn e.message
      return u.replace(/^<|>$/g, "")

  # append msg to #results
  log: (msg) ->
    jQuery("#results").append JSON.stringify(msg) + "<br/" + ">"

  # Load and show entity
  showEntity: (entityUri) ->
    @vie.load(entity: entityUri).using("stanbol").execute().success (entities) ->
      selectedEntity = _(entities).detect((ent) ->
        ent.getSubject().indexOf(entityUri) isnt -1
      )
      jQuery(".infoBox").html("").infobox
        vie: Vhealth.vie
        config: ->
          localStorage[Vhealth.lsName]
        entity: selectedEntity
        valueProcess: (value, fieldConfig) ->
          Vhealth.humanReadableValue value
        keyProcess: Vhealth.shortenUri
      # show Entity label
      jQuery(".entityLabel").html VIE.Util.getPreferredLangForPreferredProperty selectedEntity, ['skos:prefLabel', 'rdfs:label'], ["en", "de"]
      # # handle types
      # hide owl:Thing as type
      types = _([selectedEntity.get('@type')]).flatten()
      types = _(types).filter (type) ->
        Vhealth.shortenUri(type.toString()) isnt "owl:Thing"
      jQuery(".entity-types").html ""
      
      types = _(types).each (type) ->
        typeEl = jQuery "<button class='saveConfig'>save config for <b>#{Vhealth.shortenUri type.toString()}</b></button><br/>"
        jQuery(".entity-types").append typeEl
        typeEl.filter(".saveConfig").button
          entityType: type
        .click ->
          type = jQuery(@).button "option", "entityType"
          Vhealth.saveConfig type.toString()
      # 
      Vhealth.showInPropertyList selectedEntity
      event = new jQuery.Event("viehealthEntitySelection")
      event.selectedEntity = selectedEntity
      jQuery(".collector .vhealth-portlet").trigger event
      console.log selectedEntity

  # The propertyList is where all the draggable properties are listed
  showInPropertyList: (entity) ->
    jQuery(".info").html ""
    keys = _(entity.attributes).keys()
    keys = _(keys).sortBy (key) ->
      Vhealth.shortenUri(key)
    _(keys).each (key) =>
      i = 0

      # Don't process it if it's on the hidden property's list
      while i < @hiddenList.length
        hiddenItem = @hiddenList[i]
        return  if Vhealth.shortenUri(key).indexOf(hiddenItem) is 0
        i++
      # Don't process it if the property name begins with @
      return  if key.indexOf("@") is 0
      value = entity.get(key)
      val = @humanReadableValue value
      @createPortlet Vhealth.shortenUri(key), val, entity, key

    jQuery(".portlets").sortable connectWith: ".portlets"
    jQuery(".portlets").disableSelection()
    false
  # Make a value human readable. Meaning collections to <li>, uris to curie links, etc
  humanReadableValue: (value) ->
    val = ""
    if typeof value is "string"
      val = value.replace(/^<|>$/g, "")
    else if value instanceof Array
      val = "<ul>"
      _(value).each (v) =>
        label = (if @vie.namespaces.isUri(v) then "<a href='javascript:Vhealth.showEntity(\"" + v + "\")'>" + Vhealth.shortenUri(v) + "</a>" else v)
        val += "<li>" + label + "</li>"

      val += "</ul>"
    else
      val = JSON.stringify(value)
    val
  # Process one property as portlet in the info box
  createPortlet: (title, content, entity, key) ->
    # create portlet markup and init a portlet on it
    jQuery("<div title='#{title}'>#{content}</div>").appendTo(".info").portlet
      open: false
      entity: entity
      key: key
      configHtml: "<input class='field-label' value='#{title}'/>"
      # when it's created subscribe on the event 'viehealthEntitySelection'
      create: ->
        jQuery(@).bind "viehealthEntitySelection", (e) =>
          entity = e.selectedEntity
          content = Vhealth.humanReadableValue entity.get key
          if content
            jQuery(@).portlet "setContent", content
            jQuery(@).portlet "expand"
          else
            jQuery(@).portlet "setContent", ""
            jQuery(@).portlet "collapse"
  # Extract config JSONs from the collector elements and save it in the local storage
  saveConfig: (type) ->
    localStorage[Vhealth.lsName] ?= "{}"
    ls = null
    try
      ls = JSON.parse localStorage[Vhealth.lsName]
    catch e
      ls = {}
    collectors = jQuery ".collector"
    ls[type] = _(collectors).map (collector) ->
      _(jQuery(".vhealth-portlet", collector)).map (portlet) ->
        property: jQuery(portlet).portlet('option', 'key')
        fieldLabel: jQuery('input.field-label', portlet).val()
    console.info type, ls[type]
    localStorage[Vhealth.lsName] = JSON.stringify ls
    console.info localStorage[Vhealth.lsName]

  # Initialize namespaces for nicer 
  addNamespaces: ->
    @vie.namespaces.add "drugbank",       "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/"
    @vie.namespaces.add "drugcategory",   "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugcategory/"
    @vie.namespaces.add "drugtargets",    "http://www4.wiwiss.fu-berlin.de/drugbank/resource/targets/"
    @vie.namespaces.add "drugtype",       "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugtype/"
    @vie.namespaces.add "drugs",          "http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/"
    @vie.namespaces.add "dosageforms",    "http://www4.wiwiss.fu-berlin.de/drugbank/resource/dosageforms/"
    @vie.namespaces.add "drugbank-class", "http://www4.wiwiss.fu-berlin.de/drugbank/vocab/resource/class/"
    @vie.namespaces.add "side_effects",   "http://www4.wiwiss.fu-berlin.de/sider/resource/side_effects/"
    @vie.namespaces.add "diseasome",      "http://www4.wiwiss.fu-berlin.de/diseasome/resource/diseasome/"
    @vie.namespaces.add "genes",          "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/"
    @vie.namespaces.add "diseases",       "http://www4.wiwiss.fu-berlin.de/diseasome/resource/diseases/"
    @vie.namespaces.add "diseaseClass",   "http://www4.wiwiss.fu-berlin.de/diseasome/resource/diseaseClass/"
    @vie.namespaces.add "sider-drugs",    "http://www4.wiwiss.fu-berlin.de/sider/resource/drugs/"
    @vie.namespaces.add "dailymed",       "http://www4.wiwiss.fu-berlin.de/dailymed/resource/dailymed/"
    @vie.namespaces.add "dailymed-drugs", "http://www4.wiwiss.fu-berlin.de/dailymed/resource/drugs/"
    @vie.namespaces.add "ingredient",     "http://www4.wiwiss.fu-berlin.de/dailymed/resource/ingredient/"
    @vie.namespaces.add "fu-berlin-other","http://www4.wiwiss.fu-berlin.de/"

    @vie.namespaces.add "lct-intervention","http://data.linkedct.org/resource/intervention/"
    @vie.namespaces.add "lct-condition",   "http://data.linkedct.org/resource/condition/"
    @vie.namespaces.add "tcm-disease",     "http://purl.org/net/tcm/tcm.lifescience.ntu.edu.tw/id/disease/"

    @vie.namespaces.add "wdbp",            "http://www.dbpedia.org/resource/"
    @vie.namespaces.add "dbp",             "http://dbpedia.org/resource/"
    @vie.namespaces.add "dbpedia-page",    "http://dbpedia.org/"

# Plain portlet
jQuery.widget "Vie.portlet", 
  options:
    title: "default title"
    open: true
    configHtml: ""
  _create: ->
    @options.title = @element.attr("title") or @options.title
    @element.addClass "vhealth-portlet ui-widget ui-widget-content ui-helper-clearfix ui-corner-all"
    content = @element.contents()
    @element.append """
      <div class='portlet-header'>
        <span class='portlet-header-label'>#{@options.title}</span>
      </div>
    """
    if @options.configHtml 
      @element.append "<div class='portlet-content vie-portlet-config'>#{@options.configHtml}</div>"
    @element.append "<div class='portlet-content vie-portlet-content'></div>"
    @contentEl = jQuery '.vie-portlet-content', @element
    @configEl = jQuery '.vie-portlet-config', @element
    content.appendTo @contentEl

    @headerEl = jQuery '.portlet-header', @element
    @headerEl.addClass "ui-widget-header ui-corner-all"
    @headerEl.prepend "<span class='toggle-button ui-icon ui-icon-plusthick'></span>"
    @headerEl.prepend "<span class='x-button ui-icon ui-icon-closethick'></span>"

    jQuery(".toggle-button, .portlet-header-label", @element).click (event) ->
      jQuery(this).parent().find(".toggle-button").toggleClass("ui-icon-minusthick").toggleClass "ui-icon-plusthick"
      jQuery(this).parents(".vhealth-portlet:first").find(".vie-portlet-content, .vie-portlet-config").toggle()
      event.preventDefault()
    jQuery(".x-button", @element).click =>
      element = @element
      @destroy()
      element.remove()
    if @options.open
      @expand()
    else
      @collapse()

  _destroy: ->
    @element.removeClass 'vhealth-portlet ui-widget ui-widget-content ui-helper-clearfix ui-corner-all'
    content = @contentEl.contents()
    content.appendTo @element
    @contentEl.remove()
    @headerEl.remove()

  collapse: ->
    jQuery(".toggle-button", @element).removeClass("ui-icon-minusthick").addClass "ui-icon-plusthick"
    @contentEl.hide()
    @configEl.hide()

  expand: ->
    jQuery(".toggle-button", @element).addClass("ui-icon-minusthick").removeClass "ui-icon-plusthick"
    @contentEl.show()
    @configEl.show()

  setContent: (newContent) ->
    @contentEl.html newContent

jQuery.widget "Vie.infobox", 
  options:
    title: "default title"
    vie: null
    entity: null
    config: {}
    valueProcess: (value, fieldConfig) ->
      value
    keyProcess: (key) ->
      _(key).escape()
  _create: ->
  _init: ->
    unless @options.entity
    else
      @showInfo()
  showInfo: ->
    console.info "showing info in", @element
    types = _([@options.entity.get("@type")])
    .flatten()
    .map (typeObj) ->
      typeObj.toString()
    config = JSON.parse @options.config() or "{}"
    console.info config, types
    matchingConfigs = []
    for key, value of config
      if _(types).indexOf(key) isnt -1
        matchingConfigs.push value
        console.info "matching config", key, value
    unless matchingConfigs.length
      console.warn "No config for", @options.entity
    console.info "config:", matchingConfigs[0]
    _(matchingConfigs).each (config) =>
      _(config).each (box, i) =>
        boxEl = jQuery "<div class='box'></div>"
        _(box).each (field) =>
          fieldLabel = @options.keyProcess field.property
          value = @options.entity.get field.property
          humanReadableValue = @options.valueProcess value, field
          boxEl.append portletEl = jQuery("<div class='' title='#{field.fieldLabel}'>#{humanReadableValue}</div>")
          portletEl.portlet
            open: i is 0
        @element.append boxEl

