
###

  probably like:

  Materializer.build(T <: BaseModel|View, R <: BaseModel|View|Function)
  .field((x) -> s.attr())               # does it possible in coffee?
  .field('attr_name', to: "input[name='some-attr']", attribute: 'data-attr', with: () ->)
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
  - make fieldMapper
  - second add to proto
  - third integration with current


###


# ok, it's for BaseModelToView
class FieldMaker
  constructor: (@_from, @_to, @_attribute, @_with) ->

  has_to: () ->
    @_to?

  has_attribute: () ->
    @_attribute?

  has_with: () ->
    @_with?

  field: () ->
    @_from

  to: (x) ->
    if x?
      @_to = x
    else
      @_to

  attribute: (x) ->
    @_attribute = x

  with: (x) ->
    @_with = x

  # fill with default parameters
  normalize: () ->
    if !@has_with()
      @_with = (x) -> x

    if !@has_attribute()
      @_attribute = "text" # make constant


  to_string: () ->
    "#{@_from} ~> #{@_with} ~> #{@_to}##{@_attribute}"

  @build: (from) ->
    new FieldMaker(from)


class AbstractMaterializer
  constructor: (@_from, @_to) ->
    @fields = []
    @current = null

  field: (from_name) ->
    if @current?
      @current.normalize()

    @current = FieldMaker.build(from_name)
    @fields.push(@current)

  _zoom_with: (view, maybeView) ->
    if Sirius.Utils.is_string(maybeView)
      view.zoom(maybeView)
    else
      maybeView


# interface-like
class MaterializerWithImpl extends AbstractMaterializer

  with: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("With attribute must be function, #{typeof f} given")

    unless @current?
      throw new Error("Incorrect call. Call 'with' after 'to' or 'attribute'")

    unless @current.has_to()
      throw new Error("Incorrect call. Call 'to' before 'with'")

    if @current.has_with()
      throw new Error("Incorrect call. The field already has 'with' function")

    @current.with(f)
    @


class ModelToViewMaterializer extends MaterializerWithImpl
  field: (from_name) ->
    result = from_name
    if Sirius.Utils.is_function(from_name)
      result = from_name(@_from.get_binding())

    super.field(result)
    # check model attributes
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

class ViewToModelMaterializer extends MaterializerWithImpl
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
    # todo check model attributes
    unless @current?
      throw new Error("Incorrect call. Define 'field' firstly, and then call 'from'")

    if @current.has_to()
      throw new Error("Incorrect call. '#{@current.field().get_element()}' already has 'to'")

    result = attribute
    if @_to? && Sirius.Utils.is_function(attribute)
      result = attribute(@_to.get_binding())

    @current.to(result)
    @

class ViewToViewMaterializer extends ViewToModelMaterializer
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

class ViewToFunctionMaterializer extends ViewToModelMaterializer
  to: (f) ->
    unless Sirius.Utils.is_function(f)
      throw new Error("Function is required")

    super.to(f)
    @

class ModelToFunctionMaterializer extends AbstractMaterializer
  field: (attr) ->
    result = attr
    if Sirius.Utils.is_function(attr)
      result = attr(@_from.get_binding())

    super.field(result)
    # check model attributes
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


class Materializer

  # from must be View or BaseModel
  # to is View, BaseModel, or Function
  constructor: (from, to) ->
    if from instanceof Sirius.BaseModel && to instanceof Sirius.View
      return new ModelToViewMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.BaseModel
      return new ViewToModelMaterializer(from, to)
    if from instanceof Sirius.View && to instanceof Sirius.View
      return new ViewToViewMaterializer(from, to)
    if from instanceof Sirius.View && !to?
      return new ViewToFunctionMaterializer(from)
    if from instanceof Sirius.BaseModel && !to?
      return new ModelToFunctionMaterializer(from)
    else
      throw new Error("Not implemented")

  dump: () ->
    xs = @fields.map (x) -> x.to_string()
    xs.join("\n")

  to_string: () ->
    @dump()



  @build: (from, to) ->
    new Materializer(from, to)













