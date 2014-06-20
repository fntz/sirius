
###
  A base class for all models in application.
  @example
     class Person extends BaseModel
       @attrs: ["id", "name"]

       @has_many: [Group]

       @form_name: "person-model"

       @guid_for: id

       @validate:
        id:
          presence: true
          numericality: only_integers: true
        name:
          presence: true
          format: with: /^[A-Z].+/

        to_string: () ->
          "name: #{name}; id: #{id}, group count: #{@get('group').length}"

     class Group extends BaseModel
       @attrs: ["title", "person_id"]

       @belongs_to: [{model: "person", back: "id"}]

###
class Sirius.BaseModel

  #@nodoc
  attrs: () ->
    @constructor.attrs || []

  #normalize model name: UserModel => user_model
  normal_name: () ->
    Sirius.Utils.underscore(@constructor.name)

  #@nodoc
  has_many: () ->
    @constructor.has_many || []

  #@nodoc
  has_one: () ->
    @constructor.has_one || []

  #@nodoc
  belongs_to: () ->
    @constructor.belongs_to || [] #array with object

  validators: () ->
    @constructor.validate

  guid_for: () ->
    @constructor.guid_for

  ###
    Because models contain attributes as object, this method extract only keys
    attrs : [{"id" : 1}] => after normalization ["id"]
  ###
  normalize_attrs: () ->
    for a in @constructor.attrs
      do(a) ->
        if typeof(a) is "object"
          Object.keys(a)[0]
        else
          a

  ###
    Take a object with attributes for creation;
    @note: by now not supported relations!
    @example
      class MyModel extends BaseModel
        @attrs: ["id"]

      my_model = new MyModel({id: 1})

    This methods, generate properties for object from `@attrs` array.
    Each property starts with `_`.
    Also it's generated properties for `@has_many` and `@has_one` attributes.

  ###
  constructor: (obj = {}) ->
    @_isValid = false

    # object, which contain all errors, which registers after validation
    @errors = {}
    @attributes = @normalize_attrs()

    for attr in @attrs()
      if typeof(attr) is "object"
        [key, ...] = Object.keys(attr)
        throw new Error("Attributes should have a key and value") if !key
        @["_#{key}"] = attr[key]
      else
        @["_#{attr}"] = null

    for klass in @has_many()
      @["_#{klass}"] = []
      @attributes.push("#{klass}")
      @_has_create(klass)

    for klass in @has_one()
      @["_#{klass}"] = null
      @attributes.push("#{klass}")
      @_has_create(klass, true)

    if Object.keys(obj).length != 0
      for attr in Object.keys(obj)
        @set(attr, obj[attr])

    if g = @guid_for()
      @set(g, @_generate_guid())

  # generate guid from: http://stackoverflow.com/a/105074/1581531
  _generate_guid: () ->
    s4 = () -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

  _has_create: (klass, is_one = false) ->
    @["add_#{klass}"] = (z) =>
      name = z.constructor.name
      me   = @normal_name()
      m_name = @constructor.name

      expected = klass.charAt(0).toUpperCase() + klass.slice(1)
      throw new Error("Expected #{expected}, but given: #{name}") if name isnt expected

      if is_one
        if @get("#{klass}")
          throw new Error("Model #{expected} already exist for #{m_name}")
        @set("#{klass}", z)
      else
        @get("#{klass}").push(z)

      #feedback
      b_model = (for i in z.belongs_to() when i['model'] == me then i)[0]

      if !b_model
        throw new Error("Model #{name} must contain '@belongs_to: [{model: #{me}, back: #{me}_id]'")

      if !(back = b_model['back'])
        throw new Error("Define 'back' property for @belongs_to")

      if @attributes.indexOf(back) == -1
        throw new Error("Foreign key: '#{back}' not contain in a '#{m_name}' model")

      key = "#{me}_#{back}"
      if z.attributes.indexOf(key) == -1
        throw new Error("Define #{key} in @attrs for '#{expected}' model")

      z.set("#{key}", @get(back))

  # base setter
  # @throw Error, when attributes not defined for current model
  set: (attr, value) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"] = value

  # base getter
  # @throw Error, when attributes not defined for current model
  get: (attr) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"]

  # @return [Boolean] check if current model instance is valid
  valid: () ->
    @_isValid

  # @nodoc
  validate: () ->
    @errors = {}
    vv = @validators()
    for key, value of vv
      current_value = @get(key)
      for validator, v of value
        klass = switch validator
          when "length"        then new Sirius.LengthValidator()
          when "exclusion"     then new Sirius.ExclusionValidator()
          when "inclusion"     then new Sirius.InclusionValidator()
          when "format"        then new Sirius.FormatValidator()
          when "numericality"  then new Sirius.NumericalityValidator()
          when "presence"      then new Sirius.PresenceValidator()
          when "validate_with"
            z = new Sirius.Validator()
            z.validate = v
            z.msg = null
            z

        r = klass.validate(current_value, v)
        if !r
          e = if typeof(v) is "object"
                v["error"] || klass.error_message()
              else
                klass.error_message()

          (@errors["#{key}"] ?= []).push("#{e}")

    @_isValid = Object.keys(@errors).length == 0 ? true : false

  # @note must be overrided in descendants
  # @param exception [Boolean] throw exception, when true and instance not valid,
  # otherwise return false if not valid
  # @throw Error, when exception in true
  save: (exception = false) ->
    @validate()
    name = @constructor.name
    throw new Error("#{name} model not valid!") if exception && !@_isValid
    return false if @_isValid
    true

  # Convert model instance in a json
  # @param root [Boolean] when true generated json as { model_name : { attrs } }
  # otherwise as { attrs }
  #
  to_json: (root = false) ->
    z = {}

    for attr in @attributes
      value = @get("#{attr}")
      z["#{attr}"] = if @has_many().indexOf(attr) > -1
        for v in value then JSON.parse(v.to_json())
      else if @has_one().indexOf(attr) > -1
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

  # convert model into array of element instances
  # @note not support a relations
  # @return string with html
  to_html: () ->
    to = @constructor.to || {}

    result = for key in @attributes
      value = @get(key)
      obj   = to[key]    || {}
      tag   = obj["tag"] || "div"
      attr  = for k, v of obj when k isnt "tag" then "#{k} = '#{v}'"
      attr = if attr.length == 0 then "" else " #{attr.join(' ')}"

      value = if @has_many().indexOf(key) > -1
        for v in value then v.to_html()
      else if @has_one().indexOf(key) > -1
        value.to_html()
      else
        value

      "<#{tag}#{attr}>#{value}</#{tag}>"

    result.join("")
  # Create a new model instance from json structure.
  # @param json [JSON]
  # @param models [Object] a object with model classes
  # @example:
  #   # Person has many Group
  #   Person.from_json({... group: {...}}, {group: Group})
  @from_json: (json, models = {}) ->
    m = new @
    json = JSON.parse(json)
    attrs = [].concat(m.attrs(), m.has_many(), m.has_one())

    for attr in attrs
      if typeof(attr) is "object"
        [key, ...] = Object.keys(attr)
        m.set(key, json[key] || attr[key])
      else
        value = if m.has_many().indexOf(attr) > -1
          model = models[attr]
          if model
            for z in json[attr] then model.from_json(JSON.stringify(z), models)
          else
            json[attr]
        else if m.has_one().indexOf(attr) > -1
          model = models[attr]
          if model
            model.from_json(JSON.stringify(json[attr]), models)
          else
            json[attr]
        else
          json[attr]
        m.set(attr, value)
    m

  # Generate a new model instance from form
  # @note not support a relations
  @from_html: (selector) ->
    #FIXME
    form_name = selector || @.form_name || Sirius.Utils.underscore(@.name)

    @.from_json(Sirius.Application.adapter.form_to_json(form_name))

