
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

has_one, has_many must take arrays with models

belongs_to must take a array with objects as { :model => modelName[String] } with optional
  argument a foreign key :

  belongs_to { model => "person", :back => "name" }
  generate next methods:
    model_back ~> person_name

  if a belongs_to not present must be a throw exception



###

class BaseModel

  attrs: () ->
    @constructor.attrs || []

  #normalize model name: UserModel => user_model
  normal_name: () ->
    @constructor.name.replace(/([A-Z])/g, '_$1').replace(/^_/,"").toLowerCase()

  has_many: () ->
    @constructor.has_many || []

  has_one: () ->
    @constructor.has_one || []

  belongs_to: () ->
    @constructor.belongs_to || [] #array with object

  validators: () ->
    @constructor.validate

  #
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
        #FIXME : maybe normalize class name
        self["_#{klass}"] = []
        self.attributes.push("#{klass}")
        self["add_#{klass}"] = (z) =>
          name = z.constructor.name
          me   = self.normal_name()
          m_name = self.constructor.name

          expected = klass.charAt(0).toUpperCase() + klass.slice(1)
          throw "Expected #{expected}, but given: #{name}" if name isnt expected
          self.get("#{klass}").push(z)

          #feedback
          b_model = (for i in z.belongs_to()
            do(i) ->
              i if i['model'] == me
          )[0]

          if !b_model
            throw "Model #{name} must contain '@belongs_to: [{model: #{me}, back: #{me}_id]'"

          if !(back = b_model['back'])
            throw "Define 'back' property for @belongs_to"

          if self.attributes.indexOf(back) == -1
            throw "Foreign key: '#{back}' not contain in a '#{m_name}' model"

          key = "#{me}_#{back}"
          if z.attributes.indexOf(key) == -1
            throw "Define #{key} in @attrs for '#{expected}' model"

          z.set("#{key}", self.get(back))
          #TODO: logs


    for klass in @has_one()
      do(klass) ->
        self["_#{klass}"] = null
        self.attributes.push("#{klass}")
        self["add_#{klass}"] = (z) =>
          name = z.constructor.name
          me   = self.normal_name()
          m_name = self.constructor.name

          expected = klass.charAt(0).toUpperCase() + klass.slice(1)
          throw "Expected #{expected}, but given: #{name}" if name isnt expected

          if self.get("#{klass}")
            throw "Model #{expected} already exist for #{m_name}"

          self.set("#{klass}", z)

          #feedback
          b_model = (for i in z.belongs_to()
            do(i) ->
              i if i['model'] == me
          )[0]

          if !b_model
            throw "Model #{name} must contain '@belongs_to: [{model: #{me}, back: #{me}_id]'"

          if !(back = b_model['back'])
            throw "Define 'back' property for @belongs_to"

          if self.attributes.indexOf(back) == -1
            throw "Foreign key: '#{back}' not contain in a '#{m_name}' model"

          key = "#{me}_#{back}"
          if z.attributes.indexOf(key) == -1
            throw "Define #{key} in @attrs for '#{expected}' model"

          z.set("#{key}", self.get(back))
          #TODO: logs


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
        value = self.get("#{attr}")
        z["#{attr}"] = if self.has_many().indexOf(attr) > -1
          for v in value then JSON.parse(v.to_json())
        else if self.has_one().indexOf(attr) > -1
          JSON.parse(value.to_json())
        else
          value

    if root
      o = {}
      name = @normal_name()
      o[name] = z
      JSON.stringify(o)
    else
      JSON.stringify(z)


  to_html: () ->
    to = @constructor.to
    for key, attrs of to
      value = @get(key)
      tag = attrs["tag"] || "div"
      clone = {}
      for key, v of attrs when key isnt "tag" then clone[key] = v

      SiriusApplication.adapter.element(tag, value, clone)

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


#if Object.prototype.toString.call(value) is '[object Array]'
#  if value.length != 0
#
#  else
#    z["#{attr}"] = []
