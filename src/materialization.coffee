
###
  Different type of Materializers
###

# @private
# @nodoc
# I use this class for save information about Field Mapping like: names, attributes...
class Sirius.FieldMaker
  constructor: (@_from, @_to, @_attribute, @_transform, @_handle) ->

  # @return[Boolean]
  has_to: () ->
    @_to?

  # @return[Boolean]
  has_attribute: () ->
    @_attribute?

  # @return[Boolean]
  has_transform: () ->
    @_transform?

  # @return[Boolean]
  has_handle: () ->
    @_handle?

  # @return[String|Sirius.View] - current start mapping property
  field: () ->
    @_from

  # @param[String|Sirius.View]
  # @return[String|Sirius.View|Void] - current end mapping property
  to: (x) ->
    if x?
      @_to = x
    else
      @_to

  # @param x [Function]
  handle: (x) ->
    if x?
      @_handle = x
    else
      @_handle

  # @param x [String]
  attribute: (x) ->
    if x?
      @_attribute = x
    else
      @_attribute

  # @param x [Function] - a function for middle transform input changes
  transform: (x) ->
    if x?
      @_transform = x
    else
      @_transform

  # fill with default parameters
  # @return[Void]
  normalize: () ->
    if !@has_transform()
      @_transform = (x) -> x

    if !@has_attribute()
      @_attribute = "text" # make constant

  to_string: () ->
    "#{@_from} ~> #{@_transform} ~> #{@_to}##{@_attribute}"

  # Static constructor
  @build: (from) ->
    new Sirius.FieldMaker(from)

# @private
# @nodoc
# Base class for describe different types of Materializers
class Sirius.AbstractMaterializer
  # @param _from [BaseModel, Sirius.View]
  # @param _to [BaseModel, View, Function]
  constructor: (@_from, @_to) ->
    @fields = []
    @current = null

  # @param from_name [String, Sirius.View]
  field: (from_name) ->
    if @current?
      @current.normalize()

    @current = Sirius.FieldMaker.build(from_name)
    @fields.push(@current)
    @

  # @nodoc
  # @private
  _zoom_with: (view, maybeView) ->
    if Sirius.Utils.is_string(maybeView)
      view.zoom(maybeView)
    else
      maybeView

  dump: () ->
    xs = @fields.map (x) -> x.to_string()
    xs.join("\n")

  to_string: () ->
    @dump()

  get_from: () ->
    @_from

  get_to: () ->
    @_to()

  has_to: () ->
    @_to?

  fields_map: () ->
    obj = {}
    for f in @fields
      obj[f.field()] = f
    obj

  # run Materializer for given fields
  run: () ->
    throw new Error("Not Implemented")


# interface-like
# @nodoc
# @private
class Sirius.MaterializerTransformImpl extends Sirius.AbstractMaterializer

  # @param f [Function] - function for transforming results from @from to @to
  transform: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("'transform' attribute must be function, #{typeof f} given")

    unless @current?
      throw new Error("Incorrect call. Call 'transform' after 'to' or 'attribute'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'transform'")

    if @current.has_transform()
      throw new Error("Incorrect call. The field already has 'transform' function")

    @current.transform(f)
    @


# @class
# @private
# Provide binding between Sirius.BaseModel and Sirius.View
# @example
# Sirius.Materializer.build(model, view)
#   .field((x) -> x.model_attribute)
#   .to((v) -> v.zoom("input")
#   .transform((x) -> "#{x}!!!")
#   run()
#
class Sirius.ModelToViewMaterializer extends Sirius.MaterializerTransformImpl
  # @param: [String|Function]
  # if string - field should be attribute of Sirius.BaseModel instance
  # if function - a function should returns attribute.
  # function take binding object
  # @example
  #   class MyMode extends Sirius.BaseModel
  #     @attrs: ["id", "name"]
  #       @validate:
  #        id:
  #          numericality: only_integers: true
  #          presence: true
  #
  #   # then function will take the next object
  #   {
  #      id    : "id",
  #      name  : "name",
  #      'errors.id.numericality' : "errors.id.numericality",
  #      'errors.id.presence'     : "errors.id.presence",
  #      'errors.id'              : "errors.id"
  #      'errors.all'             : "errors.all"
  #   }
  #  # and you can get these:
  #
  #  (x) -> x.id
  #  (x) -> x.errors.id.numericality
  #  (x) -> x.errors.all
  #
  field: (from_name) ->
    result = from_name
    if Sirius.Utils.is_function(from_name)
      result = from_name(@_from.get_binding())

    Sirius.Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

  # @param: [String, Function, Sirius.View] - all of therse will be transformer to Sirius.View
  # if String - argument will be transformed to Sirius.View, with common Sirius.View.zoom function
  # if Sirius.View - nothing to do here
  # if Function - function will be called with @to
  # @note Should be called after 'field' function
  # @example
  #  all of below are the same
  #  to('input')
  #  to(Sirius.View('input'))
  #  to((view) -> view.zoom('input')
  #
  to: (arg) ->
    unless @current?
      throw new Error("Incorrect call. Call 'to' after 'field'")

    unless Sirius.Utils.is_function(arg) || Sirius.Utils.is_string(arg) || arg instanceof Sirius.View
      throw new Error("'to' must be string or function, or instance of Sirius.View")

    result = arg
    if Sirius.Utils.is_string(arg)
      result = @_zoom_with(@_to, arg)

    if Sirius.Utils.is_function(arg)
      result = @_zoom_with(@_to, arg(@_to))

    if @current.has_to()
      throw new Error("Incorrect call. '#{@current.field()}' already has 'to'")

    @current.to(result)
    @

  # @param String - attribute of View, whereto changes will be reflected. That's an usual html property, like
  # class, data-attribute, or checked
  # @note Should be called after `field` function, and after `to`
  # @example
  #  .attribute('data-id')
  #
  attribute: (attr) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'attribute' after 'to'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'attribute'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field()}' already has 'attribute'")

    @current.attribute(attr)
    @

  # @alias attribute
  to_attribute: (attr) ->
    @attribute(attr)

  # @param - user defined function for handle changes from BaseModel to View
  # Function will take Sirius.View (from `to`) and changes
  # @default apply `swap` strategy to `to`-attribute above
  # @note `field` should be called before, `to` should be called before
  # @example
  #
  #   .handle((view, changes) -> view.render(changes).append())
  #
  handle: (f) ->
    unless @current?
      throw new Error("Incorrect call. 'field' is not defined")

    unless @current.has_to()
      throw new Error("Incorrect call. define 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("'handle' must be a function")

    if @current.has_handle()
      throw new Error("'handle' already defined")

    @current.handle(f)
    @

  # call materializer
  run: () ->
    @current.normalize()

    obj = @fields_map()
    clb = (attribute, value) ->
      f = obj[attribute]
      if f?
        transformed = f.transform().call(null, value, f.to())
        if f.has_handle()
          f.handle().call(null, f.to(), transformed) # view and changes
        else
          # default, just a swap
          f.to().render(transformed).swap(f.attribute())

    @_from._register_state_listener(clb)

# @class
# @private
# Provide binding between Sirius.View and Sirius.BaseModel
# @example
# Sirius.Materializer.build(view, model)
#  .field((v) -> v.zoom("input"))
#  .to((m) -> m.attribute)
#  .transform((x) -> x.result)
#  .run()
class Sirius.ViewToModelMaterializer extends Sirius.MaterializerTransformImpl

  # @param element [String|Function|Sirius.View] - view where need control changes
  # if String - argument will be wrapped to Sirius.View
  # if Sirius.View - nothing to do
  # if Function - function will be called result should be a string or Sirius.View
  # @example
  #
  #  .field('input')
  #  .field((v) -> v.zoom('input')
  #  .field(new Sirius.View('input'))
  #
  field: (element) ->
    el = null
    if Sirius.Utils.is_string(element)
      el = @_from.zoom(element)
    else if Sirius.Utils.is_function(element)
      el = @_zoom_with(@_from, element(@_from))
    else if element instanceof Sirius.View
      el = element
    else
      throw new Error("Element must be string or function, or instance of Sirius.View")

    super.field(el)
    @

  # @param attribute [String]
  # control changes from specific html attribute: class, data-*, checked ...
  # @example
  # .from('data-id')
  #
  from: (attribute) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. Call 'from' before 'to'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'from'")

    @current.attribute(attribute)
    @

  # @alias from
  from_attribute: (attribute) ->
    @from(attribute)

  # @param attribute [String, Function]
  # if String - nothing to do
  # if Function - function will be called. an argument will be model.binding object (@see Sirius.ModelToViewMaterializer)
  # @note attribute should be exist in model
  # @note `field` should be called before
  # @example
  #   .field((x) -> x.attribute)
  #   .field('attribute')
  to: (attribute) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'to'")

    result = attribute
    if @_to? && Sirius.Utils.is_function(attribute)
      result = attribute(@_to.get_binding())

    if @_to? && @_to instanceof Sirius.BaseModel
      Sirius.Materializer._check_model_compliance(@_to, result)

    @current.to(result)
    @

  # run Materializer
  run: () ->
    @current.normalize()
    model = @_to
    for field in @fields
      element = field.field().get_element()
      clb = (result) ->
        transformed = field.transform().call(null, result)
        if field.to().indexOf(".") != -1 # validator
          model.set_error(field.to(), transformed)
        else
          model.set(field.to(), transformed)

      observer = new Sirius.Internal.Observer(
        element,
        element,
        field.attribute(),
        clb
      )
      field.field()._register_state_listener(observer)

# @class
# @private
# Describe View to View transformation
# @example
#
# Sirius.Materializer.build(view1, view2)
# .field((view1) -> view1.zoom('input'))
# .to((view2) -> view2.zoom('div'))
# .transform((result) -> result.text)
# .handle((transformed_result, view_to) -> view_to.render(transformed_result).append())
# .run()
#
class Sirius.ViewToViewMaterializer extends Sirius.ViewToModelMaterializer
  # @param element [String|Sirius.View|Function]
  # if String - element will be converted to Sirius.View
  # if Sirius.View - nothing to do
  # if Function - will be called with argument @to
  # @example
  #  .to('input')
  #  .to((v) -> v.zoom('input'))
  #  .to(new Sirius.View('input'))
  #
  to: (element) ->
    el = null
    if Sirius.Utils.is_string(element)
      el = @_to.zoom(element)
    else if element instanceof Sirius.View
      el = element
    else if Sirius.Utils.is_function(element)
      el = @_zoom_with(@_to, element(@_to))
    else
      throw new Error("Element must be string or function, or instance of Sirius.View")

    super.to(el)
    @

  # @param f [Function] - transformation handler
  # Function will take two arguments: changes and view from `to` method
  handle: (f) ->
    unless @current?
      throw new Error("Incorrect call. 'field' is not defined")

    unless @current.has_to()
      throw new Error("Incorrect call. define 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("'handle' must be a function")

    if @current.has_handle()
      throw new Error("'handle' already defined")

    @current.handle(f)
    @

  # run Materializer
  run: () ->
    @current.normalize()
    for field in @fields
      element = field.field().get_element()
      clb = (result) ->
        transformed = field.transform(result)
        if field.has_handle()
          field.handle().call(null, transformed, field.to())
        else
          # TODO checkbox !!!!
          field.to().render(transformed).swap()

      observer = new Sirius.Internal.Observer(
        element,
        element,
        field.attribute(),
        clb
      )
      field.field()._register_state_listener(observer)

# @class
# @private
# Describe how to pass changes from View to Function
# @example
# Sirius.Materializer.build(view)
#  .field((v) -> v.zoom('input'))
#  .to((changes) -> changes)
#  .run()
class Sirius.ViewToFunctionMaterializer extends Sirius.ViewToModelMaterializer
  # @param f [Function] - function for changes handling
  to: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    super.to(f)
    @

  # run Materializer
  run: () ->
    @current.normalize()
    # already zoomed
    for field in @fields
      element = field.field().get_element()
      observer = new Sirius.Internal.Observer(
        element,
        element,
        field.attribute(),
        field.to()
      )
      field.field()._register_state_listener(observer)

# @class
# @private
# Describe transformation from Sirius.BaseModel to function
# @example
# Sirius.Materializer.build(model)
#  .field((m) -> m.attribute)
#  .to((changes) -> changes)
#  .run()
#
class Sirius.ModelToFunctionMaterializer extends Sirius.AbstractMaterializer
  #
  # @param attr [String, Function]
  # if String - nothing to do
  # if Function - function will be called with binding parameters @see Sirius.ModelToViewMaterializer
  # @note attribute should be present in model
  field: (attr) ->
    result = attr
    if Sirius.Utils.is_function(attr)
      result = attr(@_from.get_binding())

    Sirius.Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

  # @param f [Function]
  # function should have one input parameter - actual changes from model
  to: (f) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly")

    if @current.has_to()
      throw new Error("Incorrect call. The field already has 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    @current.to(f)
    @

  # run Materialization process
  run: () ->
    obj = @fields_map()
    clb = (attribute, value) ->
      if obj[attribute]?
        obj[attribute].to().call(null, value)

    @_from._register_state_listener(clb)


class Sirius.Materializer

  # from must be View or BaseModel
  # to is View, BaseModel, or Function
  constructor: (from, to) ->
    if from instanceof Sirius.BaseModel && to instanceof Sirius.View
      return new Sirius.ModelToViewMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.BaseModel
      return new Sirius.ViewToModelMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.View
      return new Sirius.ViewToViewMaterializer(from, to)
    if from instanceof Sirius.View && !to?
      return new Sirius.ViewToFunctionMaterializer(from)
    if from instanceof Sirius.BaseModel && !to?
      return new Sirius.ModelToFunctionMaterializer(from)
    else
      throw new Error("Illegal arguments: 'from'/'to' must be instance of Sirius.View/or Sirius.BaseModel")

  # @private
  # @nodoc
  @_check_model_compliance: (model, maybe_model_attribute) ->
    name = model._klass_name()
    attrs = model.get_attributes()

    if attrs.indexOf(maybe_model_attribute) != -1
      return true
    else
      if maybe_model_attribute.indexOf(".") == -1
        throw new Error("Attribute '#{maybe_model_attribute}' not found in model attributes: '#{name}', available: '[#{attrs}]'")

      # check for validators
      splitted = maybe_model_attribute.split(".")
      if splitted.length != 3
        throw new Error("Try to bind '#{maybe_model_attribute}' from errors properties, but validator is not found, correct definition should be as 'errors.id.numericality'")

      [_, attr, validator_key] = splitted

      unless model._is_valid_validator("#{attr}.#{validator_key}")
        throw new Error("Unexpected '#{maybe_model_attribute}' errors attribute for '#{name}' (check validators)")
      else
        return true

  # static constructor
  @build: (from, to) ->
    new Sirius.Materializer(from, to)













