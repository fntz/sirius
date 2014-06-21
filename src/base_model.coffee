
#
# A top level class for all models in application.
# Supported features:
#   + to json\html convert
#   + create from json\html
#   + validation
#   + generate guid
#   + attributes support
#   + base relation support (`has_many`, `has_one`, `belongs_to`)
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id", {title: "default title"}, "description"]
#     @to:
#       id          : tag: "b", class: 'my-model-id'
#       title       : tag: "span", class: "my-model-title"
#
#   class Person extends BaseModel
#     @attrs: ["id", "name"]
#
#     @has_many: [Group]
#
#     @form_name: "person-model"
#
#     @guid_for: id
#
#     @validate:
#       id:
#         presence: true
#         numericality: only_integers: true
#       name:
#         presence: true
#         format: with: /^[A-Z].+/
#
#     @to:
#       id          : tag: "b", class: 'person-id'
#       name        : tag: "span", class: "person-name"
#       group       : tag: "p", class: "group"
#
#     to_string: () ->
#       "name: #{name}; id: #{id}, group count: #{@get('group').length}"
#
#   class Group extends BaseModel
#     @attrs: ["title", "person_id"]
#
#     @belongs_to: [{model: "person", back: "id"}]
#
# @todo Callback support
class Sirius.BaseModel
  # @property [Array<String|Object> the attributes for model
  # When attribute defined as object, then key, will be a `attribute` and `value` it's default value for this `attribute`
  # @example
  #   @attrs: ["id", "title", {description : "Lorem ipsum ..."}]
  #   //now, model attribute `description` have a default value "Lorem ipsum ..."
  #
  @attrs: []

  # @property [Array<String>] model names for relations
  # From this property, will be generated helper methods: `add_x`, where `x` is a model name
  # @note model names, should be written in the next format: ModelName => model_name
  # @example
  #   class Model extends Sirius.BaseModel
  #     @has_many: ["other_model"]
  #
  #   my_model = new Model()
  #   my_model.add_other_model(new OtherModel())
  #
  @has_many: []

  # @property [Array<String>] model names for relations
  # From this property, will be generated helper methods: `add_x`, where `x` is a model name
  # @note model names, should be written in the next format: ModelName => model_name
  # @note when you call `add_model` when `model` already exist
  # @example
  #   class MyModel extends Sirius.BaseModel
  #     @has_one: ["model"]
  #   my_model = new MyModel()
  #   my_model.add_model(new Model()) // => ok
  #   my_model.add_model(new Model()) // => oops, exception
  #   my_model.set("model", null)
  #   my_model.add_model(new Model()) // => ok
  @has_one: []

  # @property [Array<Object>] take a object `model` as model for association, and `back` as an `attributes` from `has_*` model
  # @note for use need to add into `@attrs` the next attribute: `model_back`, see example
  # @example
  #   class Person extends Sirius.BaseModel
  #     @attrs: ["id"]
  #     @has_many: ["group"]
  #
  #   class Group extends Sirius.BaseModel
  #     @attrs: ["person_id"]
  #     @belongs_to [{model: "person", back: "id"}]
  #
  #   person = new Person({id: 1})
  #   group  = new Group()
  #   person.add_group(group) // when add new group, then in `group` set a `person_id` as id from Person instance
  #
  #   group.get('person_id') // => 1
  @belongs_to: []

  # @property [Object] - object, which contain attributes names as keys, and values is a object, with properties for html element
  # @note when not set a `tag` for `attribute` default `tag` is a `div`
  # @example
  #   class Person extends Sirius.BaseModel
  #     @attrs: ["id", "name"]
  #     @to :
  #       id : tag: b, class: 'person-class'
  #  (new Person({id: 1, name: "Abc"})).to_html() # => <b class='person-class'>1</b><div>Abc</div>
  @to: {}

  # @property [String] - name for element, when you want convert html to Model
  # @note when it not define, then it's create from model name as: ModelName => model_name
  # @example
  #   class Person extends
  #     @form_name: 'a-b-c'
  #
  @form_name: null

  # @property [String] - attribute name, for which generate guid
  # @example
  #   class Person extends
  #     @attrs: ["id", "name"]
  #     @guid_for: "id"
  #
  @guid_for: null

  # @property [Object] - object, where keys, is a defined `@attrs` and values is a validator objects or function
  # @note validator object, it's a default Validators @see Sirius.Validator
  # @example
  #   class ModelwithValidators extends Sirius.BaseModel
  #   @attrs: ["id", {title: "t"}, "description"]
  #   @validate :
  #     id:
  #       presence: true,
  #       numericality: only_integers: true
  #       inclusion: within: [1..10]
  #       validate_with:  (value) ->
  #         if not condition ....
  #           @msg = .... #define a user friendly message
  #         else
  #           true
  #
  #     title:
  #       presence: true
  #       format: with: /^[A-Z].+/
  #       length: min: 3, max: 7
  #       exclusion: ["title"]
  #
  @validate : {}

  # @nodoc
  attrs: () ->
    @constructor.attrs || []

  # @nodoc
  #normalize model name: UserModel => user_model
  normal_name: () ->
    Sirius.Utils.underscore(@constructor.name)

  # @nodoc
  has_many: () ->
    @constructor.has_many || []

  # @nodoc
  has_one: () ->
    @constructor.has_one || []

  # @nodoc
  belongs_to: () ->
    @constructor.belongs_to || [] #array with object

  # @nodoc
  validators: () ->
    @constructor.validate
  # @nodoc
  guid_for: () ->
    @constructor.guid_for

  #
  #  Because models contain attributes as object, this method extract only keys
  #  attrs : [{"id" : 1}] => after normalization ["id"]
  #  @nodoc
  normalize_attrs: () ->
    for a in @constructor.attrs
      do(a) ->
        if typeof(a) is "object"
          Object.keys(a)[0]
        else
          a

  #
  # @param obj [Object] - object with keys (define with `@attrs`) and values for it.
  #
  # @example
  #   class MyModel extends Sirius.BaseModel
  #     @attrs: ["name"]
  #
  #   my_model = new MyModel({name: "Abc"})
  #   my_model.get("name") # => Abc
  #
  # @note Method generate properties for object from `@attrs` array.
  # @note Method generate properties for `@has_many` and `@has_one` attributes.
  # @note Method generate add_x, where `x` it's a attribute from `@has_many` or `@has_one`
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

  # @private
  # @nodoc
  # generate guid from: http://stackoverflow.com/a/105074/1581531
  _generate_guid: () ->
    s4 = () -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

  # @private
  # @nodoc
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

  #
  # Base setter
  # @param attr [String] - attribute
  # @param value [Any]   - value
  # @throw Error, when attributes not defined for current model
  # @return [Void]
  set: (attr, value) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"] = value

  #
  # Base getter
  # @param attr [String] - return current `value` for attribute
  # @throw Error, when attributes not defined for current model
  # @return [Any]
  get: (attr) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

    @["_#{attr}"]

  # Check, if model instance valid
  # @return [Boolean] true, when is valid, otherwise false
  valid: () ->
    @_isValid

  # @private
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

  # @note must be redefine in descendants
  # @param exception [Boolean] throw exception, when true and instance not valid,
  # otherwise return false if not valid
  # @throw Error, when `exception` in true
  # @return [Void]
  save: (exception = false) ->
    @validate()
    name = @constructor.name
    throw new Error("#{name} model not valid!") if exception && !@_isValid
    return false if @_isValid
    true

  #
  # Convert model instance in json
  # @param root [Boolean] when true generated json as { model_name : { attrs } }
  # otherwise as { attrs }
  # @return [JSON]
  #
  # @example
  #   var m = new MyModel({"id": 10, "description", "text"});
  #   m.to_json() // => {"id":10,"title":"default title","description":"text"}
  #   m.to_json(true) // => {"my_model":{"id":10,"title":"default title","description":"text"}}
  #
  #   person  = new Person({id: 1, name: "Abc"})
  #   group0  = new Group({name: "group-0"})
  #   group1  = new Group({name: "group-1"})
  #
  #   person.add_group(group0)
  #   person.add_group(group1)
  #
  #   person.to_json() // =>
  #   // {"id":1,
  #   //  "name":"Abc",
  #   //   "group":[
  #   //     {"name":"group-0","person_id":1},
  #   //     {"name":"group-1","person_id":1}
  #   //   ]
  #   // }
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

  #
  # Convert model into array of element instances
  # @return [String]
  #
  # @example
  #   var m = new MyModel({"id": 10, "title": "my title", "description": "text..."});
  #   m.to_html() // => "<b class = 'my-model-id'>10</b><span class = 'my-model-title'>my title</span><div>text...</div>"
  #
  #   person.to_html() // =>
  #   // "<b class='person-id'>1</b>
  #   //  <span class='person-name'>Abc</span>
  #   //    <p class = 'group'>
  #   //      <span>group-0</span>
  #   //      <div>1</div>
  #   //      <span>group-1</span>
  #   //      <div>1</div>
  #   //    </p>
  #
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
  # @param json [JSON] - json object
  # @param models [Object] - object with model classes, see examples
  # @return [T < Sirius.BaseModel]
  #
  # @example
  #   var json = JSON.stringify({"id": 10, "description": "text"});
  #   var m = MyModel.from_json(j);
  #   m.get("id") // => 10
  #   m.get("description") // => "text"
  #   m.get("title") // => "default title"
  #
  #   var json = JSON.stringify({"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}]})
  #   var person = Person.from_json(json, {group: Group});
  #   person.get('group') // => [Group, Group]
  #
  #   var person0 = Person.from_json(json)
  #   person.get('group') // => [{name: 'group-0', ... }, {name: 'group-1', ...}]
  #
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

  #
  # Generate a new model instance from form
  # @param selector [String] - element selector, for find element, where model may be present in html
  # @return [T < Sirius.BaseModel]
  #
  # @example
  #   //html form
  #   <form name="my_model" id="my-model-form">
  #     <input type="hidden" name="id" class="my-id" value="1" />
  #     <input type="text" name="title" class="title" value="new title" />
  #     <textarea name="description">text...</textarea>
  #   </form>
  #
  #   var m = MyModel.from_html("#my-model-form");
  #   m.get("id")          // => 1
  #   m.get("title")       // => new title
  #   m.get("description") // => text...
  #
  #
  @from_html: (selector) ->
    #FIXME
    form_name = selector || @.form_name || Sirius.Utils.underscore(@.name)

    @.from_json(Sirius.Application.adapter.form_to_json(form_name))

