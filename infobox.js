// Generated by CoffeeScript 1.3.1

/*
# Infobox widget
The Infobox widget allows you to show an info box as a side panel in a generic way.
Given you have some sort of data source connected through VIE, providing VIE entities,
and a list of configurations (plain JSON object) describing how a specific entity
is to be shown depending what type entity has. Now when you simply give the 
Infobox widget a VIE entity or simply an entity URI which the widget can load 
from your data source, through VIE, the widget can automatically show the information
in the way it's described by the configuration object.

## Usage
## Instantiate VIE

      vie = new VIE()
        vie.use new vie.StanbolService(
          url: "http://dev.iks-project.eu:8081"
          enhancerUrlPostfix: "/enhancer/chain/ehealth"
          entityhubSite: "ehealth"
          proxyDisabled: true
          getSources: [
            uri: "www4.wiwiss.fu-berlin.de"
            label: "ehealth"
          ]
        )

        config = {
            "<http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/drugs>":[[
                {
                    "property":"<http://www.w3.org/2004/02/skos/core#prefLabel>"
                    "fieldLabel":"Name"
                    "template": "<img src='#{value}'/>"
                }
                {"property":"<http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/description>","fieldLabel":"Description"}
            ],[],[{"property":"<http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/target>","fieldLabel":"Targets"}],[{"property":"<http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugbank/toxicity>","fieldLabel":"Toxicity"}]]}

see [config utility](http://szabyg.github.com/vie-health/app.html) for 
creating such configurations

## Instantiating the widget:

        jQuery(".infoBox").infobox
          vie: vie
          service: "stanbol"
          config: ->
            localStorage.infoboxConfig

## Telling the widget what entity to show

        jQuery('.infobox').infobox 'option', 'entity', 'http://www4.wiwiss.fu-berlin.de/drugbank/resource/drugs/DB00945'
        jQuery('.infobox').infobox('methodName', par1, par2)
*/


(function() {

  jQuery.widget("Vie.infobox", {
    options: {
      title: "default title",
      vie: null,
      service: "stanbol",
      entity: null,
      config: {},
      valueProcess: function(value, fieldConfig) {
        return this._humanReadableValue(value);
      },
      keyProcess: function(key) {
        return _(key).escape();
      }
    },
    _create: function() {
      this._setEntity(this.options.entity);
      this.uniq = this._generateUUID();
      this.element.addClass(this.uniq);
      return this.element.addClass('vie-infobox');
    },
    _destroy: function() {
      this.element.removeClass(this.uniq);
      return this.element.removeClass('vie-infobox');
    },
    _init: function() {
      if (this.options.entity) {
        return this.showInfo();
      }
    },
    _setOption: function(key, value) {
      switch (key) {
        case "entity":
          return this._setEntity(value);
      }
    },
    _setEntity: function(entity) {
      var _this = this;
      if (entity) {
        if (typeof entity === "string") {
          return this.loadEntity(entity, function(res) {
            _this.entity = res;
            return _this.showInfo();
          });
        } else {
          this.entity = entity;
          return this.showInfo();
        }
      } else {
        return this.cleanUp();
      }
    },
    loadEntity: function(entityUri, cb) {
      this.entityUri = entityUri;
      return this.options.vie.load({
        entity: entityUri
      }).using(this.options.service).execute().success(function(entities) {
        return cb(_(entities).detect(function(ent) {
          return ent.getSubject().indexOf(entityUri) !== -1;
        }));
      });
    },
    showInfo: function() {
      var matchingConfig,
        _this = this;
      this.cleanUp();
      console.info("showing info in", this.element);
      matchingConfig = this._getMatchingConfig(this.entity, this._getConfig());
      console.info("config:", matchingConfig);
      return _(matchingConfig).each(function(box, i) {
        var boxEl;
        boxEl = jQuery("<div class='box'></div>");
        _(box).each(function(field) {
          var fieldLabel, humanReadableValue, portletEl, value;
          fieldLabel = _this.options.keyProcess(field.property);
          value = _this.entity.get(field.property);
          humanReadableValue = _this.options.valueProcess.apply(_this, [value, field]);
          boxEl.append(portletEl = jQuery("<div class='' title='" + field.fieldLabel + "'>" + humanReadableValue + "</div>"));
          return portletEl.portlet({
            open: i === 0
          });
        });
        return _this.element.append(boxEl);
      });
    },
    cleanUp: function() {
      return this.element.html("");
    },
    _getMatchingConfig: function(entity, config) {
      var key, matchingConfigs, types, value;
      types = _([entity.get("@type")]).flatten().map(function(typeObj) {
        return typeObj.toString();
      });
      console.info(config, types);
      matchingConfigs = [];
      for (key in config) {
        value = config[key];
        if (_(types).indexOf(key) !== -1) {
          matchingConfigs.push(value);
          console.info("matching config", key, value);
        }
      }
      if (!matchingConfigs.length) {
        console.warn("No config for", entity);
        alert("No config found for the selected entity. See more details in the console.");
      }
      return matchingConfigs[0];
    },
    _getConfig: function(conf) {
      var c, res;
      c = conf || this.options.config;
      res = c;
      if (typeof c === "string") {
        res = JSON.parse(c || "{}");
      }
      if (typeof c === "function") {
        res = this._getConfig(c());
      }
      return res;
    },
    _humanReadableValue: function(value) {
      var val,
        _this = this;
      val = "";
      if (typeof value === "string") {
        val = value.replace(/^<|>$/g, "");
      } else if (value instanceof Array) {
        val = "<ul>";
        _(value).each(function(v) {
          var label, uri;
          if (_this.options.vie.namespaces.isUri(v)) {
            uri = v.replace(/^<|>$/g, "");
            label = "" + (_this._shortenUri(v)) + "&nbsp;\n<small>(<a href=\"javascript:jQuery('." + _this.uniq + "').infobox('option', 'entity', '" + v + "')\">follow</a>&nbsp;\n&nbsp;<a href='" + uri + "' target='_blank'>browser</a>)</small>";
          } else {
            label = v.toString();
          }
          return val += "<li>" + label + "</li>";
        });
        val += "</ul>";
      } else if (typeof value === "object" && value["@value"]) {
        val = value.toString();
      } else {
        val = JSON.stringify(value);
      }
      return val;
    },
    _shortenUri: function(u) {
      try {
        return this.options.vie.namespaces.curie(u);
      } catch (e) {
        console.warn(e.message);
        return u.replace(/^<|>$/g, "");
      }
    },
    _generateUUID: function() {
      var S4;
      S4 = function() {
        return ((1 + Math.random()) * 0x10000 | 0).toString(16).substring(1);
      };
      return "" + (S4()) + (S4()) + "-" + (S4()) + "-" + (S4()) + "-" + (S4()) + "-" + (S4()) + (S4()) + (S4());
    }
  });

  jQuery.widget("Vie.portlet", {
    options: {
      title: "default title",
      open: true,
      configHtml: "",
      alt: "",
      configInit: function(el) {}
    },
    _create: function() {
      var content,
        _this = this;
      this.options.title = this.element.attr("title") || this.options.title;
      this.element.addClass("infobox-portlet ui-widget ui-widget-content ui-helper-clearfix ui-corner-all");
      content = this.element.contents();
      this.element.append("<div class='portlet-header'>\n  <span class='portlet-header-label' alt=" + this.options.alt + " title=" + this.options.alt + ">" + this.options.title + "</span>\n</div>");
      if (this.options.configHtml) {
        this.element.append("<div class='portlet-content vie-portlet-config'>" + this.options.configHtml + "</div>");
        this.configEl = jQuery(".vie-portlet-config", this.element);
        this.options.configInit(this.configEl);
      }
      this.element.append("<div class='portlet-content vie-portlet-content'></div>");
      this.contentEl = jQuery('.vie-portlet-content', this.element);
      this.configEl = jQuery('.vie-portlet-config', this.element);
      content.appendTo(this.contentEl);
      this.headerEl = jQuery('.portlet-header', this.element);
      this.headerEl.addClass("ui-widget-header ui-corner-all");
      if (this.options.configHtml) {
        this.headerEl.prepend(" <i class='settings-button fa-icon icon-cog'></i> ");
      }
      this.headerEl.prepend(" <i class='toggle-button fa-icon icon-plus'></i> ");
      this.headerEl.prepend(" <i class='x-button fa-icon icon-remove'></i> ");
      jQuery(".toggle-button, .portlet-header-label", this.element).click(function(e) {
        jQuery(this).parent().find(".toggle-button").toggleClass("icon-minus").toggleClass("icon-plus");
        if (jQuery(this).parent().find(".toggle-button").hasClass("icon-plus")) {
          jQuery(this).parents(".infobox-portlet:first").find(".vie-portlet-content, .vie-portlet-config").hide();
        } else {
          jQuery(this).parents(".infobox-portlet:first").find(".vie-portlet-content").show();
        }
        return e.preventDefault();
      });
      jQuery(".x-button", this.element).click(function() {
        var element;
        element = _this.element;
        _this.destroy();
        return element.remove();
      });
      this.configEl.hide();
      jQuery(".settings-button", this.element).click(function() {
        return _this.configEl.toggle();
      });
      if (this.options.open) {
        return this.expand();
      } else {
        return this.collapse();
      }
    },
    _destroy: function() {
      var content;
      this.element.removeClass('infobox-portlet ui-widget ui-widget-content ui-helper-clearfix ui-corner-all');
      content = this.contentEl.contents();
      content.appendTo(this.element);
      this.contentEl.remove();
      return this.headerEl.remove();
    },
    collapse: function() {
      jQuery(".toggle-button", this.element).removeClass("icon-minus").addClass("icon-plus");
      this.contentEl.hide();
      return this.configEl.hide();
    },
    expand: function() {
      jQuery(".toggle-button", this.element).addClass("icon-minus").removeClass("icon-plus");
      return this.contentEl.show();
    },
    setContent: function(newContent) {
      return this.contentEl.html(newContent);
    }
  });

}).call(this);
