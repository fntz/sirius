
###

  class Person extends BaseModel
    @attrs: ["id", "name"]

    @has_many: [Group]

    @form_name: "person-model"

    @validate:
      id:
        presence: true
        numericality: only_integers: true
      name:
        presence: true
        format: with: /^[A-Z].+/

    group_names: () ->
      for g in @get('group') then g.get("name")

  class Group extends BaseModel
    @attrs: ["name"]
    has_one: Person

has_many should generate next methods:
   add_model
   and set a for _model [] as value


has_one it's the same as attr but with
   add_model under hood
   set('model', model)


###

class BaseModel
  attrs: () ->
    @constructor.attrs || []

  normal_name: () ->
    @constructor.name.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

  has_many: () ->
    @constructor.has_many || []

  has_one: () ->
    @constructor.has_one || []

  validators: () ->
    @constructor.validate

  normalize_attrs: () ->
    for a in @constructor.attrs
      do(a) ->
        if typeof(a) is "object"
          Object.keys(a)[0]
        else
          a

  constructor: (obj = {}) ->
    self = @

    @_isValid = false
    @errors = {}
    @attributes = @normalize_attrs()

    for attr in @attrs()
      do(attr) ->
        if typeof(attr) is "object"
          [key, ...] = Object.keys(attr)
          throw new Error("Attributes should have a key and value") if !key
          self["_#{key}"] = attr[key]
        else
          self["_#{attr}"] = null

    for klass in @has_many()
      do(klass) ->
        self["_#{klass}"] = []
        self.attributes.push("#{klass}")
        self["add_#{klass}"] = (z) ->
          name = z.constructor.name
          me = self.normal_name()
          expected = klass.charAt(0).toUpperCase() + klass.slice(1)
          throw "Expected #{expected}, but given: #{name}" if name isnt expected
          #feedback
          if z.attributes.indexOf(me) > -1
            if z.has_one().indexOf(me) > -1
              m = z.get("#{me}")
              z.set("#{me}", self) if !m
            else if z.has_many().indexOf(me) > -1
              z.get("#{me}").push(self)


          self.get("#{klass}").push(z)

    for klass in @has_one()
      do(klass) ->
        self["_#{klass}"] = null
        self.attributes.push("#{klass}")
        self["add_#{klass}"] = (z) ->
          name = z.constructor.name
          me = self.normal_name()
          expected = klass.charAt(0).toUpperCase() + klass.slice(1)
          throw "Expected #{expected}, but given: #{name}" if name isnt expected

          t = self.get("#{klass}")
          throw "Model #{klass} exist" if t

          if z.attributes.indexOf(me) > -1
            if z.has_one().indexOf(me) > -1
              m = z.get("#{me}")
              z.set("#{me}", self) if !m
            else if z.has_many().indexOf(me) > -1
              z.get("#{me}").push(self)

          self.set("#{klass}", z)


    if Object.keys(obj).length != 0
      for attr in Object.keys(obj)
        do(attr) ->
          self.set(attr, obj[attr])


  set: (attr, value) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    # TODO validate value
    @["_#{attr}"] = value

  get: (attr) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"]

  valid: () ->
    @_isValid

  validate: () ->
    @errors = {}
    vv = @validators()
    for key, value of vv
      current_value = @get(key)
      for validator, v of value
        klass = switch validator
          when "length"       then new LengthValidator()
          when "exclusion"    then new ExclusionValidator()
          when "inclusion"    then new InclusionValidator()
          when "format"       then new FormatValidator()
          when "numericality" then new NumericalityValidator()
          when "presence"     then new PresenceValidator()

        r = klass.validate(current_value, v)
        if !r
          e = if typeof(v) is "object"
                v["error"] || klass.error_message()
              else
                klass.error_message()

          (@errors["#{key}"] ?= []).push("#{e}")

    @_isValid = Object.keys(@errors).length == 0 ? true : false

  save: (exception = false) ->
    @validate()
    name = @constructor.name
    throw new Error("#{name} model not valid!") if exception && !@_isValid
    return false if @_isValid
    true

  to_json: (root = false) ->
    self = @
    z = {}

    for attr in @attributes
      do(attr) ->
        z["#{attr}"] = self.get("#{attr}")

    if root
      o = {}
      name = @normal_name()
      o[name] = z
      JSON.stringify(o)
    else
      JSON.stringify(z)


  to_html: () ->
    to = @constructor.to
    self = @
    result = for key, attrs of to
      value = self.get(key)
      tag = attrs["tag"] || "div"
      delete attrs["tag"]
      SiriusApplication.adapter.element(tag, value, attrs)
    result

  @from_json: (json = {}) ->
    m = new @
    json = JSON.parse(json)
    for attr in m.attrs()
      do(attr) ->
        if typeof(attr) is "object"
          [key, ...] = Object.keys(attr)
          m.set(key, json[key] || attr[key])
        else
          m.set(attr, json[attr])
    m

  @from_html: () ->
    #FIXME
    form_name = @.form_name || @.name.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

    @.from_json(SiriusApplication.adapter.form_to_json("form[name='#{form_name}'"))


