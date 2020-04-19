
###

  probably like:

  Materializer.build(T <: BaseModel|View, R <: BaseModel|View|Function)
  .field((x) -> s.attr())               # does it possible in coffee?
  # or
  field('attr_name').to("input").attribute("data-attr").with(() ->)

  field('attr_name).to("input")
  .dump() => log output as string, dump is a terminal operation
  # or build
  # does it possible?
  field('attr_name').to((v) -> v.zoom('input')).attribute('data-attr').with(() -> )

  # TODO spec syntax, add to .prototype.
  field((model) -> model.from{or something like that}.attr())
  field( view -> view.zoom("el"))

  # view to view
  Materializer.build(v1, v2)
  .field("element").from("attribute").to("element).with((v2, v1_attribute) -> )
  .field(v -> v.zoom("element")).from("attribute").to(v2 -> v.zoom("el"))
  .with(() ->)
  # or
  .field("element").from("attr").with((v2, attr) -> ) # user decides what should do with v2 (zoom) and attr

 # view to model
  Materilizer.build(v, m)
  .field("element").from("attr").to('m_attr')
  .field(v -> v.zoom("el")).from("attr").to(m -> m.attr_name)
   with ? (m, attr_changes) -> ??? is it need?

 # view to function
  Materializer.build(v) # second param is empty
  .field('element').attribute('data-class').to((changes) ->)

 # model to function
 Materializer.build(m) # second param is empty
  .field('attr').to(changes) -> )

 # first iteration:
  - third integration with current


###


# ok, it's for BaseModelToView
class Sirius.FieldMaker
  constructor: (@_from, @_to, @_attribute, @_transform, @_handle) ->

  has_to: () ->
    @_to?

  has_attribute: () ->
    @_attribute?

  has_transform: () ->
    @_transform?

  has_handle: () ->
    @_handle?

  field: () ->
    @_from

  to: (x) ->
    if x?
      @_to = x
    else
      @_to

  handle: (x) ->
    if x?
      @_handle = x
    else
      @_handle

  attribute: (x) ->
    if x?
      @_attribute = x
    else
      @_attribute

  transform: (x) ->
    if x?
      @_transform = x
    else
      @_transform

  # fill with default parameters
  normalize: () ->
    if !@has_transform()
      @_transform = (x) -> x

    if !@has_attribute()
      @_attribute = "text" # make constant


  to_string: () ->
    "#{@_from} ~> #{@_transform} ~> #{@_to}##{@_attribute}"

  @build: (from) ->
    new Sirius.FieldMaker(from)


class Sirius.AbstractMaterializer
  constructor: (@_from, @_to) ->
    @fields = []
    @current = null

  field: (from_name) ->
    if @current?
      @current.normalize()

    @current = Sirius.FieldMaker.build(from_name)
    @fields.push(@current)

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

  materialize: () ->
    @fields

  run: () ->
    throw new Error("Not Implemented")


# interface-like
class Sirius.MaterializerTransformImpl extends Sirius.AbstractMaterializer

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



class Sirius.ModelToViewMaterializer extends Sirius.MaterializerTransformImpl
  field: (from_name) ->
    result = from_name
    if Sirius.Utils.is_function(from_name)
      result = from_name(@_from.get_binding())

    Sirius.Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

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

  attribute: (attr) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'attribute' after 'to'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'attribute'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field()}' already has 'attribute'")

    @current.attribute(attr)
    @

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


  run: () ->
    @current.normalize()

    obj = @fields_map()
    clb = (attribute, value) ->
      f = obj[attribute]
      if f?
        transformed = f.transform().call(this, value, f.to())
        if f.has_handle()
          f.handle().call(null, f.to(), transformed) # view and changes
        else
          # default, just a swap
          f.to().render(transformed).swap(f.attribute())

    @_from._register_state_listener(clb)


class Sirius.ViewToModelMaterializer extends Sirius.MaterializerTransformImpl
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

  from: (attribute) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. Call 'from' before 'to'")

    if @current.has_attribute()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'from'")

    @current.attribute(attribute)
    @

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


class Sirius.ViewToViewMaterializer extends Sirius.ViewToModelMaterializer
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

  run: () ->
    @current.normalize()
    for field in @fields
      element = field.field().get_element()
      clb = (result) ->
        transformed = field.transform(result)
        if field.has_handle()
          field.handle().call(this, transformed, field.to())
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


class Sirius.ViewToFunctionMaterializer extends Sirius.ViewToModelMaterializer
  to: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    super.to(f)
    @

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


class Sirius.ModelToFunctionMaterializer extends Sirius.AbstractMaterializer
  field: (attr) ->
    result = attr
    if Sirius.Utils.is_function(attr)
      result = attr(@_from.get_binding())

    Sirius.Materializer._check_model_compliance(@_from, result)

    super.field(result)

    @

  to: (f) ->
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly")

    if @current.has_to()
      throw new Error("Incorrect call. The field already has 'to'")

    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    @current.to(f)
    @

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


  @build: (from, to) ->
    new Sirius.Materializer(from, to)













