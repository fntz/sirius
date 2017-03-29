
# private class
class ComputedField
  # @fields array of string
  # fn - function which compute result. By default joun
  constructor: (@main, @fields, @fn = null) ->
    @_count = @fields.length
    @_values = []

  get_fields: () -> @fields

  complete: (field, value) ->
    o = {}
    o[field] = value
    v = @_values.map (f) -> Object.keys(f)[0]
    if v.indexOf(field) == -1
      @_values.push(o)
      if @is_full()
        @_result()
      else
        null
    else
      null

  field_name: () -> @main

  remove: (field) ->
    delete @_values[field]

  # return result
  _result: () ->
    v = @_values
    args = @fields.map (f) ->
      (v.filter (vv) -> vv[f])[0][f]

    if @fn == null
      args.join(" ")
    else
      @fn.apply(null, args)

  is_full: () ->
    @_values.length == @_count



#
# A top level class for all models in application.
# Supported features:
#   + to json
#   + create from json
#   + validation
#   + generate guid
#   + attributes support
#   + base relation support (`has_many`, `has_one`, `belongs_to`)
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id", {title: "default title"}, "description"]
#
#   class Person extends BaseModel
#     @attrs: ["id", "name"]
#
#     @has_many: [Group]
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
  # @private
  # Contain all validator pairs.
  @_Validators = []

  ###
    the attributes for model.

    When attribute defined as object, then key, will be a `attribute` and `value` it's default value for this `attribute`
    @example
      @attrs: ["id", "title", {description : "Lorem ipsum ..."}]
      //now, model attribute `description` have a default value "Lorem ipsum ..."
  ###
  @attrs: []

  ###
   Skip fields, when it not define in model

   @example

      class ModelA extends Sirius.BaseModel
        @attrs: ["id"]

      class ModelB extends Sirius.BaseModel
        @attrs: ["id"]
        @skip : true

      obj = {"id": 1, "foo" : "bar" }
      new ModelA(obj) # => error
      new ModelB(obj) # => ok
  ###
  @skip: false

  ###
    model names for relations.

    From this property, will be generated helper methods: `add_x`, where `x` is a model name
    @note model names, should be written in the next format: ModelName => model_name
    @example
      class Model extends Sirius.BaseModel
        @has_many: ["other_model"]

      my_model = new Model()
      my_model.add_other_model(new OtherModel())
  ###
  @has_many: []

  ###
    model names for relations.

    From this property, will be generated helper methods: `add_x`, where `x` is a model name
    @note model names, should be written in the next format: ModelName => model_name
    @note when you call `add_model` when `model` already exist
    @example
       class MyModel extends Sirius.BaseModel
         @has_one: ["model"]
       my_model = new MyModel()
       my_model.add_model(new Model()) // => ok
       my_model.add_model(new Model()) // => oops, exception
       my_model.set("model", null)
       my_model.add_model(new Model()) // => ok
  ###
  @has_one: []
  ###
    take a object `model` as model for association, and `back` as an `attributes` from `has_*` model,
    key will be created with `compose` function, by default `compose` is a `(model, back) -> "#{model}_#{back}"`

  @note for use need to add into `@attrs` the next attribute: `model_back`, see example
    @example
       class Person extends Sirius.BaseModel
         @attrs: ["id"]
         @has_many: ["group"]

       class Group extends Sirius.BaseModel
         @attrs: ["person_id"]
         @belongs_to [{model: "person", back: "id", compose: (model, back) -> "#{model}_#{back}"}]

       person = new Person({id: 1})
       group  = new Group()
       person.add_group(group) // when add new group, then in `group` set a `person_id` as id from Person instance

       group.get('person_id') // => 1
  ###
  @belongs_to: []

  ###
    attribute name, for which generate guid
    @example
       class Person extends
         @attrs: ["id", "name"]
         @guid_for: "id"
  ###
  @guid_for: null

  ###
    object, where keys, is a defined `@attrs` and values is a validator objects or function

    @note validator object, it's a default Validators @see Sirius.Validator
    @example
       class ModelwithValidators extends Sirius.BaseModel
         @attrs: ["id", {title: "t"}, "description"]
         @validate :
           id:
             presence: true,
             numericality: only_integers: true
             inclusion: within: [1..10]
             validate_with:  (value) ->
               if not condition ....
                 @msg = .... #define a user friendly message
               else
                 true

           title:
             presence: true
             format: with: /^[A-Z].+/
             length: min: 3, max: 7
             exclusion: ["title"]
  ###
  @validate : {}

  # save transformers for model
  _listeners: []

  # last argument function
  #
  # usage:
  #
  # class MyModel extends Sirius.BaseModel
  #   @attrs: ["first_name", "last_name"]
  #   @comp("default_computed_field", "first_name", "last_name")
  #   @comp("full_name", "first_name", "last_name", (f,l) -> "#{f}~#{l}")
  #
  #
  @comp: (args...) ->
    # TODO check cyclic references
    @::_cmp ||= []
    @::_cmp_fields ||= []
    @::_cmp_refs ||= {}

    if args.length == 0
      throw new Exception("Compute field is empty")
    if args.length == 2
      throw new Exception("For computed fields need more fields")

    field = args[0]
    length = args.length
    [deps, xs, fn] = if Sirius.Utils.is_function(args[length - 1])
      fn = args[length - 1]
      [args.slice(1, length - 1), args.slice(1, length - 1), fn]
    else
      [args.slice(1), args.slice(1), null]

    # fields must be unique
    # var unique = a.filter(function(item, i, ar){ return ar.indexOf(item) === i; });
    full = [field].concat(deps)
    uniq = full.filter (e, i, a) -> a.indexOf(e) == i
    if uniq.length != full.length
      throw new Error("Seems your calculated fields are not unique: [#{full}]")

    # check that field is exist
    _tmp = @attrs.concat(@::_cmp_fields)
    deps.forEach (f) ->
      if _tmp.indexOf(f) == -1
        throw new Error("Field is '#{f}' not found, for '#{field}'")

    # check cyclic references
    if @::_cmp_fields.length > 0
      r = deps.filter (f) => @::_cmp_refs[f] && @::_cmp_refs[f].indexOf(field) != -1
      if r.length > 0
        throw new Error("Cyclic references detected in '#{field}' field")

    Sirius.Application.get_logger()
    .info("Define compute field '#{field}' <- '[#{deps}]'",
      Sirius.Application.get_logger().base_model)

    @::_cmp_refs[field] = deps
    @::_cmp_fields.push(field)
    @::_cmp.push(new ComputedField(field, xs, fn))



  # @nodoc
  attrs: () ->
    (@constructor.attrs || []).concat(@constructor::_cmp_fields)

  # @nodoc
  __name: 'BaseModel' # because in IE not work construction like given_class.__super__.constructor.name

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

  # @nodoc
  _compute: (field, value) ->
    self = @
    @constructor::_cmp.forEach (cf) ->
      if cf.get_fields().indexOf(field) != -1
        r = cf.complete(field, value)
        if cf.is_full() # progress
          self._set(cf.field_name() , r)


  #
  #  Because models contain attributes as object, this method extract only keys
  #  attrs : [{"id" : 1}] => after normalization ["id"]
  #  @nodoc
  normalize_attrs: () ->
    for a in @attrs()
      do(a) ->
        if Sirius.Utils.is_object(a)
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
    # pre init
    @constructor::_cmp ||= []
    @constructor::_cmp_fields ||= []

    @logger = Sirius.Application.get_logger()
    @callbacks = []
    # object, which contain all errors, which registers after validation
    @errors = {}
    @attributes = @normalize_attrs()
    name = Sirius.Utils.fn_name(@constructor)
    @errors = {}
    @_is_valid_attr = {} # save pair attribute and validation state
    attrs0 = @attrs()

    for attr in attrs0
      # @attrs: [{key: value}]
      @logger.info("define '#{JSON.stringify(attr)}' attribute for '#{name}'", @logger.base_model)
      if Sirius.Utils.is_object(attr)
        [key, ...] = Object.keys(attr)
        if !key
          msg = "Attributes should have a key and value"
          @logger.error("#{msg}", @logger.base_model)
          throw new Error(msg)
        @["_#{key}"] = attr[key]
        @_gen_method_name_for_attribute(key)
      else
        @_gen_method_name_for_attribute(attr)
        @["_#{attr}"] = null

    for klass in @has_many()
      @logger.info("BaseModel: has many attribute: #{klass}", @logger.base_model)
      @["_#{klass}"] = []
      @attributes.push("#{klass}")
      @_has_create(klass)
      @_gen_method_name_for_attribute(klass, true)

    for klass in @has_one()
      @logger.info("BaseModel: has one attribute: #{klass}", @logger.base_model)
      @["_#{klass}"] = null
      @attributes.push("#{klass}")
      @_has_create(klass, true)
      @_gen_method_name_for_attribute(klass, true)

    skip = @constructor.skip
    attributes = @attributes
    # @attributes.indexOf(attr)
    if Object.keys(obj).length != 0
      for attr in Object.keys(obj)
        if !(attributes.indexOf(attr) == -1 && skip)
          @_attribute_present(attr)
          oldvalue = @["_#{attr}"]
          @["_#{attr}"] = obj[attr]
          @_call_callbacks(attr, obj[attr], oldvalue)


    if g = @guid_for()
      @set(g, @_generate_guid())

    # need define validators key
    @_registered_validators = @constructor._Validators
    @_registered_validators_keys = @_registered_validators.map((arr) -> arr[0])
    @_model_validators = @validators()
    for key, value of @_model_validators
      @errors[key] = {}
      @_is_valid_attr[key] = false
      for validator_name, validator of value
        if @_registered_validators_keys.indexOf(validator_name) == -1 && validator_name != 'validate_with'
          throw new Error("Unregistered validator: #{validator_name}")
        @errors[key][validator_name] = ""


    @after_create()

  # @private
  # @nodoc
  # "key-1" -> key_1
  _gen_method_name_for_attribute: (attribute, when_has_attribute = false) ->
    normalize_name = Sirius.Utils.underscore(attribute)
    throw new Error("Method #{normalize_name} already exist") if Object.keys(@).indexOf(normalize_name) != -1
    @[normalize_name] = (value) =>
      if value?
        if when_has_attribute
          @["add_#{attribute}"](value)
        else
          @set(attribute, value)
      else
        @get(attribute)


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

      key = (b_model['compose'] || (model, back) -> "#{model}_#{back}")(me, back)
      if z.attributes.indexOf(key) == -1
        throw new Error("Define #{key} in @attrs for '#{expected}' model")

      z.set("#{key}", @get(back))

  #
  #
  # @return [Array] - return all attributes for current model
  get_attributes: () ->
    @attributes


  _is_computed_attribute: (attr) ->
    if @constructor::_cmp_fields.indexOf(attr) != -1
      true
    else
      false

  _attribute_present: (attr) ->
    throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if @attributes.indexOf(attr) == -1

  _call_callbacks: (attr, value, oldvalue) ->
    for clb in @_listeners
      clb.apply(null, [attr, value])

    for clb in @callbacks
      if clb[0] is attr
        clb[1].apply(null, [attr, value, oldvalue])

    @after_update(attr, value, oldvalue)
  #
  # Base setter
  # @param attr [String] - attribute
  # @param value [Any]   - value
  # @note if attribute is object, then and value should be object, if value keys and values copy into attribute object
  # @throw Error, when attributes not defined for current model
  # @return [Void]
  set: (attr, value) ->
    if @_is_computed_attribute(attr)
      throw new Error("Impossible set computed attribute #{attr} for #{@normal_name().toUpperCase()}")

    @_set(attr, value)


  _set: (attr, value) ->
    @_attribute_present(attr)

    oldvalue = @["_#{attr}"]

    if Sirius.Utils.is_object(oldvalue)
      if !Sirius.Utils.is_object(value)
        throw new Error("Attribute '#{attr}' is object, but value '#{value}' not object.")
      for k, v of value
        oldvalue[k] = v
    else
      @["_#{attr}"] = value

    @validate(attr)
    @_compute(attr, value)
    @_call_callbacks(attr, value, oldvalue)

  #
  # Base getter
  # @param attr [String] - return current `value` for attribute
  # @throw Error, when attributes not defined for current model
  # @return [Any]
  get: (attr) ->
    @_attribute_present(attr)
    @["_#{attr}"]


  # reset all attributes and validators in initial state
  # @param [String...] - attributes for reset, by default reset all attributes
  # for string into ""
  # for num into 0
  # for array into []
  # fixme default attributes
  # @return [Void]
  reset: (args...) ->
    attrs = @attributes
    for attr in args
      throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model") if attrs.indexOf(attr) == -1
      key = "_#{attr}"
      if typeof(@[key]) is 'number'
        @[key] = 0
      if Sirius.Utils.is_string(@[key])
        @[key] = ""
      if Sirius.Utils.is_array(@[key])
        @[key] = []
      if @errors[key]?
        @errors[key] = {}

    return


  # Check, if model instance valid
  # @return [Boolean] true, when is valid, otherwise false
  is_valid: () ->
    Object.keys(@_is_valid_attr).filter((key) => !@_is_valid_attr[key]).length == 0

  # Call when you want validate model
  # @nodoc
  validate: (field = null) ->
    #FIXME work with relations
    Object.keys(@_model_validators || {}).filter(
      (key) ->
        if field?
          key == field
        else
          true
    ).map((key) => # key is a current attribute
      current_value = @get(key)
      value = @_model_validators[key]

      for validator_key, validator_value of value
        klass = if validator_key is "validate_with"
          z = new Sirius.Validator()
          z.validate = validator_value
          z.msg = null
          z
        else
          z = @_registered_validators.filter((arr) -> arr[0] == validator_key)[0][1]
          new z()

        result = klass.validate(current_value, validator_value)

        if !result # when `validate` return false
          @errors[key][validator_key] = klass.error_message()
          @_is_valid_attr[key] = false
        else #when true, then need set null for error
          @errors[key][validator_key] = ""
          @_is_valid_attr[key] = true

    )


    return

  # @param [String] - attr name, if attr not given then return `errors` object,
  # otherwise return array with errors for give field
  # @return [Object|Array] - return object with errors for current model
  get_errors: (attr = null) ->
    if @attributes.indexOf(attr) == -1 && attr != null
      throw new Error("Attribute '#{attr}' not found for #{@normal_name().toUpperCase()} model")

    if attr?
      result = []
      for key, value of @errors[attr]
        if value != ""
          result.push(value)

      result
    else
      @errors

  # @param [String] - error string
  # Use for after server side validation
  # @example
  #   ajax.request
  #     onError: (xhr) ->
  #       model.set_error("title.length", xhr.responseText)
  #
  #
  set_error: (error, txt) ->
    keys = error.split(".")
    if keys.length != 2
      throw new Error("Error must be pass as 'attr.validator' like 'name.length'")

    @errors[keys[0]][keys[1]] = txt
    @_is_valid_attr[keys[0]] = false

  # @note must be redefine in descendants
  # @param exception [Boolean] throw exception, when true and instance not valid,
  # otherwise return false if not valid
  # @throw Error, when `exception` in true
  # @return [Void]
  save: (exception = false) ->
    @validate()
    name = @constructor.name
    throw new Error("#{name} model not valid!") if exception && !@is_valid()
    return false if @is_valid()
    true

  #
  # Convert model instance in json
  # @param [Array] - excluded attributes
  # @return [JSON]
  #
  # @example
  #   m = new MyModel({"id": 10, "description", "text"});
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
  to_json: (args...) ->
    z = {}

    for attr in @attributes when args.indexOf(attr) == -1
      value = @get("#{attr}")
      z["#{attr}"] = if @has_many().indexOf(attr) > -1
        for v in value then JSON.parse(v.to_json())
      else if @has_one().indexOf(attr) > -1
        JSON.parse(value.to_json())
      else
        value

    JSON.stringify(z)

  # Create a new model instance from json structure.
  # @param json [JSON] - json object
  # @param models [Object] - object with model classes, see examples
  # @return [T < Sirius.BaseModel]
  #
  # @example
  #   json = JSON.stringify({"id": 10, "description": "text"});
  #   m = MyModel.from_json(j);
  #   m.get("id") // => 10
  #   m.get("description") // => "text"
  #   m.get("title") // => "default title"
  #
  #   json = JSON.stringify({"id":1,"group":[{"name":"group-0","person_id":1},{"name":"group-1","person_id":1}]})
  #   person = Person.from_json(json, {group: Group});
  #   person.get('group') // => [Group, Group]
  #
  #   person0 = Person.from_json(json)
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
        m.set(attr, value || m.get(attr))
    m

  # usage for comparing models
  # When equal return true, otherwise return false
  # @param other [T] - other model instance
  compare: (other) ->
    throw new Error("`compare` method must be overridden")

  # callback, run after model created
  # must be overridden in user model
  after_create: () ->

  # callback, run after model will be updated
  # @param [String] - attribute which will be updated
  # @param [Any] - new value for attribute
  # @param [Any] - old value for attribute
  after_update: (attribute, newvalue, oldvalue) ->

  # method for clone current model and create new
  clone: () ->
    @constructor.from_json(@to_json())

  # Sirius.ToViewTransformer
  _register_state_listener: (transformer) ->
    @logger.debug("Register new listener for #{@constructor.name}", @logger.base_model)
    @_listeners.push(transformer)

  _clear_state_listener: (transformer) ->
    # TODO

  pipe: (func, via) ->
    # TODO default attributes
    t = new Sirius.Transformer(@, func)
    t.run(via)

    return

  #
  # bind
  #
  # Method for bind model and view, all changes in model will be reflected in view.
  #
  # @param [Sirius.View] - you view for binding
  # @param [Object] - object setting, should contain params for element.
  # Instead of object setting, when you want bind more then one attribute use
  # `data-bind-view-from` for define attribute from model, which will be used for element.
  # element attribute defined with `data-bind-view-to`.
  # `data-bind-view-from` - for model attribute.
  # `data-bind-view-to` - for view attribute. By default it `text` (or value for input)
  #
  # @example
  #   //html:
  #   <input type='text' id='my-elem' />
  #
  #   model = new Model({title: ""})
  #   view = new Sirius.View("#my-elem")
  #   model.bind(view, {from: 'title', to : 'text'})
  #   # is equal
  #   model.bind(view, {from: 'title'})  # because by default 'to' is 'text'
  #   # then
  #   model.title("new title") # change model attribute
  #   # in view
  #   $("#my-elem").val() # => new title
  #
  #   # for element attribute
  #   model.bind(view, {from: 'title', to : 'data-title'})
  #   # then
  #   model.title("new title")
  #   # in view
  #   $("#my-elem").data('name') # => new title
  #
  #   # For logical element like a checkbox, radio and select possible use
  #
  #   //html
  #   <form id='my-form'>
  #     <input type="checkbox" value="val1" data-bind-view-from='model_value' />
  #     <input type="checkbox" value="val2" data-bind-view-from='model_value' />
  #     <input type="checkbox" value="val3" data-bind-view-from='model_value' />
  #   </form>
  #
  #   # you model is only Model with one attribute `model_value`
  #   model = new Model()
  #   view = new Sirius.View("#my-form")
  #   model.bind(view)
  #
  #   # use it
  #   model.model_value("val3")
  #   # in element
  #   $("#my-form input:checked").val() # => val3
  #
  #   The same for radio or select elements.
  #
  # Use data transformation and strategies
  #
  # @example
  #     <span data-bind-view-from='title' data-bind-view-transform='wrap' data-bind-view-strategy='append'></span>
  #
  # From js code use css selectors for binding
  # @example
  #
  #    // html
  #    <div class='some-class'>
  #       <input type="text" />
  #       <div class="description"></div>
  #    </div>
  #
  #    # coffee
  #    model = new MyModel() # with id, title, description fields
  #    view = new Sirius.View(".some-class")
  #    model.bind(view, {
  #       'input[type="text"]': {from: "title"},
  #       '.description' : {from: "description"}
  #    })
  #
  # Binding flow will be
  # set new title in model -> transform with wrap method -> apply strategy -> result
  #
  # @note when you bind logical elements (option, radio or checkbox) value not changes if not present in `value` attribute
  #
  # @note when you use double side binding, and set the new value which equal previous, value has not changed
  #
  bind: (view, object_setting = {}) ->
    current_model = @

    if !(view.name && view.name() == "View")
      msg = "Sirius.BaseModel#bind only work with Sirius.View"
      @logger.error(msg, @logger.base_model)
      throw new Error(msg)

    @logger.info("Bind with #{view.element}", @logger.base_model)

    # if not transform for given key define default transform method
    Object.keys(object_setting).map (key) =>
      if Sirius.Utils.is_array(object_setting[key])
        for i in [0...object_setting[key].length]
          if !object_setting[key][i]['transform']?
            @logger.info("bind define default transform method for '#{key}'", @logger.base_model)
            object_setting[key][i]['transform'] = (x) -> x
      else
        if !object_setting[key]['transform']?
          @logger.info("bind define default transform method for '#{key}'", @logger.base_model)
        object_setting[key]['transform'] = (x) -> x


    callbacks = @callbacks
    errors = @errors
    logger = @logger

    Sirius.Application.get_adapter().and_then (adapter) =>
      current = view.element

      elements = new Sirius.BindHelper(current, false)
      .extract(adapter, object_setting)

      attributes = @attributes
      self = @

      for element in elements
        do(element) ->
          # it attribute or property
          element.view ?= new Sirius.View(element.element)
          strategy = element.strategy
          transform = element.transform

          if !Sirius.View.is_valid_strategy(strategy)
            logger.error("Not valid strategy: '#{strategy}'", logger.base_model)
            throw new Error("Strategy #{strategy} not valid")

          # for attributes
          if attributes.indexOf(element.from) != -1
            clb = (attr, value, oldvalue) ->
              result = element.transform(value)
              tag = adapter.get_attr(element.element, 'tagName')
              type = adapter.get_attr(element.element, 'type')
              # recursion detect
              # fixme maybe only for double side binding

              if element.to is 'text' && tag != "SELECT" && (["checkbox", "radio"].indexOf(type) == -1)
                if adapter.text(element.element) == result
                  return
              else
                # for checked fixme
                return if adapter.get_attr(element.element, element.to) == result

              if attr is element.from
                if element.to is 'text'
                  if tag == 'OPTION'
                    current_value = adapter.get_attr(element.element, 'value')
                    if current_value == value
                      adapter.set_prop(element.element, 'selected', true)
                  else
                    element.view.render(result)[strategy](element.to)
                else if element.to is 'checked'
                  current_value = adapter.get_attr(element.element, 'value')
                  if value[current_value]?
                    if value[current_value] == true
                      adapter.set_prop(element.element, 'checked', true)
                    else
                      adapter.set_prop(element.element, 'checked', false)
                    if type == 'radio'
                      # need reset oldvalue manually
                      for k, v of oldvalue when current_value != k
                        self["_#{attr}"][k] = false
                else
                  element.view.render(result)[strategy](element.to)
            callbacks.push([element.from, clb])
          else
            # for bind errors
            from = element.from
            if from.indexOf("errors") != 0
              throw new Error("BaseModel for bind errors need pass 'errors.attr.validator' like: 'errors.name.length'")

            prop = from.split(".")

            logger.info("bind '#{element.from}' for model", logger.base_model)

            if prop.length == 3
              element.view.bind(current_model.errors, prop[1..-1].join("."), {
                to: element.to,
                strategy: strategy,
                transform: transform
              })
            else if prop.length == 2
              key = prop[1]
              Object.keys(errors[key]).forEach((validator_name) ->
                element.view.bind(current_model.errors, "#{key}.#{validator_name}", {
                  to: element.to,
                  strategy: strategy,
                  transform: transform
                })
              )
            else
              throw new Error("Impossible bind '#{from}' with model")

              # aggregate bind all errors for on attribute


      # set default attributes, if present
      # FIXME possible stackoverflow in IE9
      # and need unbind event from current view and then bind again
      for attr in @attributes when @get(attr) != null
        @set(attr, @get(attr))





  #
  # bind2
  # double-sided binding
  # @param [Sirius.View] klass - Sirius.View
  bind2: (klass) ->
    @bind(klass)
    if klass.name && klass.name() == "View"
      if klass['bind'] && Sirius.Utils.is_function(klass['bind'])
        klass.bind(@)
      else
        new Error("For double-sided binding need bind method, but it not found in #{klass}")
    else
      new Error("BaseModel#bind2 work only with Sirius.View")

  #
  # Helper for inline create model. Use it for creation models from javascript
  #
  # @example
  #   setting = {attrs: ["id"], guid_for: "id", instance_method: function() { } }
  #   var MyModel = Sirius.BaseModel.define_model(setting)
  #
  #   var instance = new MyModel()
  #   instance.id() # => some uuid
  #   instance.instance_method() # => call method
  #
  @define_model: (setting) ->
    predefined_attributes = ['attrs', 'has_many', 'has_one', 'belongs_to', 'guid_for', 'validate']

    class Tmp extends Sirius.BaseModel
      @attrs      : setting.attrs || []
      @has_many   : setting.has_many || []
      @has_one    : setting.has_one || []
      @belongs_to : setting.belongs_to || []
      @guid_for   : setting.guid_for || null
      @validate   : setting.validate || {}

    # define instance methods
    for k, v of setting when predefined_attributes.indexOf(k) == -1
      Tmp.prototype[k] = v

    Tmp
  # Register pair - name and class for validate
  # @param [String] - validator name
  # @param [T <: Sirius.Validator] - class which extend Sirius.Validator
  #
  # @example
  #
  #   class MyValidator extends Sirius.Validator
  #     validate: (value, attributes) ->
  #       if value.length != 3
  #         @msg = "Error, #{value} must be have length 3, #{value.length} given"
  #         false
  #       else
  #         true
  #
  #   Sirius.BaseModel.register_validator('my_validator' MyValidator)
  #
  #   # then in you model
  #   class MyModel extends Sirius.BaseModel
  #     @attrs: ['name']
  #     @validate:
  #       name:
  #         my_validator : true
  #
  # @return [Void]
  @register_validator: (name, klass) ->
    logger = Sirius.Application.get_logger()
    logger.info("register validator: #{name}", logger.base_model)
    @_Validators.push([name, klass])
    null

Sirius.BaseModel.register_validator("length", Sirius.LengthValidator)
Sirius.BaseModel.register_validator("exclusion", Sirius.ExclusionValidator)
Sirius.BaseModel.register_validator("inclusion", Sirius.InclusionValidator)
Sirius.BaseModel.register_validator("format", Sirius.FormatValidator)
Sirius.BaseModel.register_validator("numericality", Sirius.NumericalityValidator)
Sirius.BaseModel.register_validator("presence", Sirius.PresenceValidator)





















