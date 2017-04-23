
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
#   + computed fields
#   + generate guid
#   + attributes support
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id", {title: "default title"}, "description"]
#
#   class Person extends BaseModel
#     @attrs: ["id", "name"]
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
#       "name: #{name}; id: #{id}}"
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
    @::_cmp ||= []
    @::_cmp_fields ||= []
    @::_cmp_refs ||= {}

    if args.length == 0
      throw new Exception("Compute field is empty")
    if args.length == 2
      txt = '@comp("default_computed_field", "first_name", "last_name")'
      throw new Exception("Define compute field like: '#{txt}'")

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
  _klass_name: () ->
    @constructor.name

  # @nodoc
  validators: () ->
    @constructor.validate
  # @nodoc
  guid_for: () ->
    tmp = @constructor.guid_for
    if tmp
      if Sirius.Utils.is_string(tmp)
        [tmp]
      else if Sirius.Utils.is_array(tmp)
        tmp
      else
        throw new Error("'@guid_for' must be array of string, but #{typeof(tmp)} given")
    else
      []


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
  constructor: (obj = {}) ->
    # pre init
    @constructor::_cmp ||= []
    @constructor::_cmp_fields ||= []

    @_listeners = []


    @logger = Sirius.Application.get_logger()
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


    for g in @guid_for()
      @logger.debug("Generate guid for '#{@_klass_name()}.#{g}'", @logger.base_model)
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


    @after_create()

  # @private
  # @nodoc
  # "key-1" -> key_1
  _gen_method_name_for_attribute: (attribute) ->
    normalize_name = Sirius.Utils.underscore(attribute)
    throw new Error("Method #{normalize_name} already exist") if Object.keys(@).indexOf(normalize_name) != -1
    @[normalize_name] = (value) =>
      if value?
        @set(attribute, value)
      else
        @get(attribute)


  # @private
  # @nodoc
  # generate guid from: http://stackoverflow.com/a/105074/1581531
  _generate_guid: () ->
    s4 = () -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

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
    throw new Error("Attribute '#{attr}' not found for #{@_klass_name()} model") if @attributes.indexOf(attr) == -1

  _call_callbacks: (attr, value, oldvalue) ->
    for clb in @_listeners
      clb.apply(null, [attr, value])

    @after_update(attr, value, oldvalue)

  # @_call_callbacks_for_errors(key, validator_key, "")
  _call_callbacks_for_errors: (key, validator_key, message) ->
    key = "errors.#{key}.#{validator_key}"
    for clb in @_listeners
      clb.apply(null, [key, message])
  #
  # Base setter
  # @param attr [String] - attribute
  # @param value [Any]   - value
  # @note if attribute is object, then and value should be object, if value keys and values copy into attribute object
  # @throw Error, when attributes not defined for current model
  # @return [Void]
  set: (attr, value) ->
    if @_is_computed_attribute(attr)
      throw new Error("Impossible set computed attribute #{attr} for #{@_klass_name()}")

    @_set(attr, value)


  _set: (attr, value) ->
    @_attribute_present(attr)

    oldvalue = @["_#{attr}"]

    @["_#{attr}"] = value

    @logger.debug("[#{@constructor.name}] set: 'attr' to '#{value}'", @logger.base_model)

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
    @logger.debug("Reset attributes: '#{args}' for #{@_klass_name()}")
    for attr in args
      throw new Error("Attribute '#{attr}' not found for #{@_klass_name()} model") if attrs.indexOf(attr) == -1
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
    model = @_klass_name()
    logger = @logger
    ln = @logger.base_model
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

        logger.debug("Validate: '#{model}.#{key} = #{current_value}' with '#{validator_key}' validator, valid?: '#{result}'", ln)

        message = if !result # when `validate` return false
          @errors[key][validator_key] = klass.error_message()
          @_is_valid_attr[key] = false
          klass.error_message()
        else #when true, then need set null for error
          delete @errors[key][validator_key]
          @_is_valid_attr[key] = true
          ""
        @_call_callbacks_for_errors(key, validator_key, message)
    )


    return

  # @param [String] - attr name, if attr not given then return `errors` object,
  # otherwise return array with errors for give field
  # @return [Object|Array] - return object with errors for current model
  get_errors: (attr = null) ->
    if @attributes.indexOf(attr) == -1 && attr != null
      throw new Error("Attribute '#{attr}' not found for #{@_klass_name()} model")

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
    JSON.stringify(@to_object(args...))

  to_object: (args...) ->
    z = {}

    for attr in @attributes when args.indexOf(attr) == -1
      value = @get(attr)
      z[attr] = value
    z

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
    attrs = [].concat(m.attrs())

    for attr in attrs
      if typeof(attr) is "object"
        [key, ...] = Object.keys(attr)
        m.set(key, json[key] || attr[key])
      else
        value = json[attr]
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

    # sync state
    _attrs = @get_attributes()
    for attr in _attrs
      if @["_#{attr}"] isnt null
        transformer.apply(null, [attr, @["_#{attr}"]])

  pipe: (func, via = {}) ->
    # TODO default attributes
    t = new Sirius.Transformer(@, func)
    t.run(via)

    return

  bind: (func, via = {}) ->
    @pipe(func, via)
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
    predefined_attributes = ['attrs', 'guid_for', 'validate']

    class Tmp extends Sirius.BaseModel
      @attrs      : setting.attrs || []
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





















