
# private class
class ComputedField
  # @fields array of string
  # fn - function which compute result. By default null
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

    Default values should be defined with object {key:value} pair. See example below
    @example
      @attrs: ["id", "title", {description : "Lorem ipsum ..."}]
      //now, the attribute `description` has a default value "Lorem ipsum ..."
  ###
  @attrs: []

  ###
   Skip fields, when they are not defined in model.

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
    attribute name, guid will be generated for that field
    @example
       class Person extends
         @attrs: ["id", "name"]
         @guid_for: "id"
  ###
  @guid_for: null

  ###
    object, where keys are defined `@attrs` and values are validator objects or function

    @note validator object, it's a default Validators @see Sirius.Validator
    @example
       class ModelWithValidators extends Sirius.BaseModel
         @attrs: ["id", {title: "t"}, "description"]
         @validate :
           id:
             presence: true,
             numericality: only_integers: true
             inclusion: within: [1..10]
             validate_with:  (value) ->
               if not condition ....
                 @msg = .... # some user-friendly message
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

  # last argument is a function
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
      throw new Error("Computed fields are empty")
    if args.length == 2
      txt = '@comp("default_computed_field", "first_name", "last_name")'
      throw new Error("Define compute field like: '#{txt}'")

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
        throw new Error("Field '#{f}' was not found, for '#{field}'")

    # check cyclic references
    # probably this part of code is unreachable, because I do not see how to make such properties
    # because comp arguments should be defined one by one (no forward references)
    # maybe I should make comp is lazy ?
    if @::_cmp_fields.length > 0
      r = deps.filter (f) => @::_cmp_refs[f] && @::_cmp_refs[f].indexOf(field) != -1
      if r.length > 0
        throw new Error("Cyclic references were detected in '#{field}' field")

    Sirius.Application.get_logger("Sirius.BaseModel")
    .info("Define compute field '#{field}' <- '[#{deps}]'")

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
    @constructor.validate || {}

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
  #  Because models can fit the attributes as an object, this method will fetch only keys
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
  # @note Method will generate properties for object from `@attrs` array.
  constructor: (obj = {}) ->
    # pre init
    @constructor::_cmp ||= []
    @constructor::_cmp_fields ||= []

    @_listeners = []

    @logger = Sirius.Application.get_logger(@constructor.name)
    # save errors, which will be added after validation
    @errors = {}
    @attributes = @normalize_attrs()
    name = @constructor.name
    @errors = {}
    @_is_valid_attr = {}     # save pair attribute and validation state
    attrs0 = @attrs()        # from class body

    @binding = {}

    for attr in attrs0
      # @attrs: [{key: value}]
      @logger.info("define '#{JSON.stringify(attr)}' attribute for '#{name}'")
      if Sirius.Utils.is_object(attr)    # {k: v}
        tmp = Object.keys(attr)
        key = tmp[0]
        if tmp.length == 0               # empty object
          msg = "@attrs must be defined as: '@attrs:['id', {'k':'v'}]'"
          @logger.error("#{msg}")
          throw new Error(msg)
        # method uniques defined below
        @["_#{key}"] = attr[key]
        @_gen_method_name_for_attribute(key)
      else                               # just a property
        @_gen_method_name_for_attribute(attr)
        @["_#{attr}"] = null

    skip = @constructor.skip
    attributes = @attributes
    # @attributes.indexOf(attr)
    # remove below line if...
    for attr in Object.keys(obj)
      if !(attributes.indexOf(attr) == -1 && skip)
        @_attribute_present(attr)
        oldvalue = @["_#{attr}"]
        @["_#{attr}"] = obj[attr]
        @_call_callbacks(attr, obj[attr], oldvalue)


    for g in @guid_for()
      @logger.debug("Generate guid for '#{@_klass_name()}.#{g}'")
      @set(g, @_generate_guid())

    # need define validators key
    @_registered_validators = @constructor._Validators # @see register_validator
    @_registered_validators_keys = @_registered_validators.map((arr) -> arr[0]) # Object.keys todo
    @_model_validators = @validators()
    @_applicable_validators = {}
    for key, value of @_model_validators       # like: `id: length: min: 3, max: 7}`, k: id, v: ...
      @errors[key] = {}
      @_is_valid_attr[key] = false
      for validator_name, validator_properties of value
        validator = @_registered_validators[validator_name]
        if @_registered_validators_keys.indexOf(validator_name) == -1 && validator_name != Sirius.Validator.ValidateWith
          throw new Error("Unregistered validator: '#{validator_name}'")

        if validator_name is Sirius.Validator.ValidateWith && !Sirius.Utils.is_function(validator_properties)
          throw new Error("Validator for attribute: '#{key}.#{validator_name}' should be a function, #{typeof(validator_properties)} given")

        [name, klass] = if validator_name == Sirius.Validator.ValidateWith
          custom_validator = new Sirius.Validator()
          custom_validator.validate = validator_properties
          custom_validator.msg = null
          [Sirius.Validator.ValidateWith, custom_validator]
        else
          custom_validator = @_registered_validators.filter((arr) -> arr[0] == validator_name)[0][1]
          [validator_name, new custom_validator()]

        # attribute: {validator_key: validator_instance}
        tmp = @_applicable_validators[key] || {}
        tmp[name] = klass
        @_applicable_validators[key] = tmp

    @_gen_binding_names()

    @after_create()

  # @private
  # @nodoc
  # "key-1" -> key_1
  _gen_method_name_for_attribute: (attribute) ->
    normalize_name = Sirius.Utils.underscore(attribute)
    throw new Error("Method '#{normalize_name}' already exist") if Object.keys(@).indexOf(normalize_name) != -1
    @[normalize_name] = (value) =>
      if value?
        @set(attribute, value)
      else
        @get(attribute)

  _gen_binding_names: () ->
    # attributes + validators
    # @_applicable_validators # {id: presence : P, numbericalluy: N ...}
    obj = {}
    for attribute in @get_attributes()
      obj[attribute] = attribute
    # TODO check model should not contains 'error' attribute
    if Object.keys(@_applicable_validators).length != 0
      errors = {}
      # id: presence, num, custom
      for key, value of @_applicable_validators
        tmp = {}
        for v in Object.keys(value)
          tmp[v] = "errors.#{key}.#{v}"
        errors[key] = tmp
      obj['errors'] = errors

    @binding = obj

  get_binding: () ->
    @binding


  # @private
  # @nodoc
  # generate guid from: http://stackoverflow.com/a/105074/1581531
  _generate_guid: () ->
    s4 = () -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}"

  # @return [Array] - return all attributes for the model
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
  # an attribute will be updated only if the attriubute is valid
  # @throw Error, when attributes not defined for current model
  # @return [Void]
  set: (attr, value) ->
    if @_is_computed_attribute(attr)
      throw new Error("Impossible set computed attribute '#{attr}' in '#{@_klass_name()}'")

    @_set(attr, value)

  _set: (attr, value, force = false) ->
    @_attribute_present(attr)

    oldvalue = @["_#{attr}"]

    @["_#{attr}"] = value

    @validate(attr)

    # is should set any way if force is true
    flag = force || @is_valid(attr)

    if flag
      @logger.debug("[#{@constructor.name}] set: '#{attr}' to '#{value}'")
      @_compute(attr, value)
      @_call_callbacks(attr, value, oldvalue)
    else
      @["_#{attr}"] = oldvalue

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
  # set every attribute to null
  # fixme default attributes
  # @return [Void]
  reset: (args...) ->
    tmp = if args? && args.length != 0
      args
    else
      @attrs()
    @logger.debug("Reset attributes: '#{tmp.join(",")}' for #{@_klass_name()}")
    for attr in tmp
      @_set(attr, null, true)
      if @errors[attr]?
        @errors[attr] = {}

    return

  # @private
  # @nodoc
  _is_valid_validator: (str) -> # id.numericality
    tmp = str.split(".")
    if tmp.length == 2 # @_applicable_validators: {id: {presence: ..., numericality: ...}
      [attribute, validator_key] = tmp
      @_applicable_validators[attribute]? && @_applicable_validators[attribute][validator_key]?

    else
      false

  # Check, if model instance is valid
  # @return [Boolean] true, when is valid, otherwise false
  is_valid: (attr = null) ->
    if attr?
      if @_is_valid_attr[attr]?
        @_is_valid_attr[attr]
      else
        true
    else
      Object.keys(@_is_valid_attr).filter((key) =>
        !@_is_valid_attr[key]
      ).length == 0


  # Call when you want validate model
  # @nodoc
  validate: (field = null) ->
    model = @_klass_name()
    logger = @logger

    all_validators = Object.keys(@_model_validators || {})

    xs = if field?
      all_validators.filter((key) -> key == field)
    else
      all_validators

    for key in xs
      current_value = @get(key)
      applicable_validators = @_model_validators[key]               # validators for the attribute

      # length: max: 3 <- !
      for validator_key, validator_properties of applicable_validators
        validator_instance = @_applicable_validators[key][validator_key]
        validation_result = validator_instance.validate(current_value, validator_properties)

        logger.debug("Validate: '#{model}.#{key} = #{current_value}' with '#{validator_key}' validator, valid?: '#{validation_result}'")

        message = unless validation_result # when `validate` return false
          @errors[key][validator_key] = validator_instance.error_message()
          @_is_valid_attr[key] = false
          validator_instance.error_message()
        else                             #when true, then need set null for error
          delete @errors[key][validator_key]
          @_is_valid_attr[key] = true
          ""
        # ? is it need? or only fail-flow
        @_call_callbacks_for_errors(key, validator_key, message)

    return

  # @param [String] - attr name, if attr not given then return `errors` object,
  # otherwise return array with errors for give field
  # @return [Object|Array] - return object with errors for current model
  get_errors: (attr = null) ->
    if attr?
      @_attribute_present(attr)
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
      throw new Error("Message must be pass as 'attr.validator' like 'name.length'")

    [key, validator_key] = keys

    unless @_applicable_validators[key][validator_key]?
      throw new Error("Unexpected key: '#{validator_key}' for '#{key}' attribute")

    @errors[key][validator_key] = txt
    @_is_valid_attr[key] = false
    @_call_callbacks_for_errors(key, validator_key, txt)

  # @note must be redefine in descendants
  # return false if not valid
  # @return [Boolean]
  save: () ->
    @validate()
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
  # @return [T < Sirius.BaseModel]
  #
  # @example
  #   json = JSON.stringify({"id": 10, "description": "text"});
  #   m = MyModel.from_json(j);
  #   m.get("id") // => 10
  #   m.get("description") // => "text"
  #   m.get("title") // => "default title"
  #
  @from_json: (json) ->
    m = new @
    json = JSON.parse(json)
    attrs = [].concat(m.attrs())

    for attr in attrs
      if typeof(attr) is "object"
        tmp = Object.keys(attr)
        key = tmp[0]
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

  # @private
  # @nodoc
  # Sirius.ToViewTransformer
  _register_state_listener: (transformer) ->
    @logger.debug("Register new listener for #{@constructor.name}")
    @_listeners.push(transformer)

    # sync state ????
    _attrs = @get_attributes()
    for attr in _attrs
      if @["_#{attr}"] isnt null
        transformer.apply(null, [attr, @["_#{attr}"]])

  # Register pair - name and class for validate
  # @param [String] - validator name
  # @param [T <: Sirius.Validator] - class which extends Sirius.Validator
  #
  # @example
  #
  #   class MyValidator extends Sirius.Validator
  #     validate: (value, attributes) ->
  #       if value.length != 3
  #         @msg = "Error, #{value} must have length 3, #{value.length} given"
  #         false
  #       else
  #         true
  #
  #   Sirius.BaseModel.register_validator('my_validator' MyValidator)
  #
  #   # then in your model
  #   class MyModel extends Sirius.BaseModel
  #     @attrs: ['name']
  #     @validate:
  #       name:
  #         my_validator : true
  #
  # @return [Void]
  @register_validator: (name, klass) ->
    logger = Sirius.Application.get_logger("Sirius.BaseModel.Static")
    logger.info("register validator: #{name}")
    @_Validators.push([name, klass])
    null

  # @private
  # @nodoc
  @_run_base_model_validator_registration: () ->
    Sirius.BaseModel.register_validator("length", Sirius.LengthValidator)
    Sirius.BaseModel.register_validator("exclusion", Sirius.ExclusionValidator)
    Sirius.BaseModel.register_validator("inclusion", Sirius.InclusionValidator)
    Sirius.BaseModel.register_validator("format", Sirius.FormatValidator)
    Sirius.BaseModel.register_validator("numericality", Sirius.NumericalityValidator)
    Sirius.BaseModel.register_validator("presence", Sirius.PresenceValidator)

Sirius.BaseModel._run_base_model_validator_registration()



















