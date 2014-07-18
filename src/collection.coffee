
# A class which implement collection interface.
# You might use it as alternative standard javascript arrays.
#
# @example
#
#   class MyModel extends Sirius.BaseModel
#     @attrs: ["id"]
#
#   myCollection = new Sirius.Collection(MyModel, [], {
#     every: 1000,
#     on_remove: () ->
#       json = ... # ajax call
#       return json
#
#     on_remove: (model) ->
#       id = model.id
#       #ajax call with id
#
#     on_add: (model) ->
#       $('list-of-models').append(model.to_html())
#
#   })
#
#  myModel = new MyModel({"id" : 1}
#  myCollection.add(myModel)
#  myCollection.add(new MyModel({"id" : 2})
#  myCollection.add(new MyModel({"id" : 3})
#
#  myCollection.index(myModel) # => 0
#  myCollection.find("id", 1)  # => MyModel Instance
#  myCollection.find("id", 1)  # => [ MyModel Instances ]
#  myCollection.filter( (model) -> model.get("id") > 2 ) # => [ MyModel Instances ]
#  myCollection.first() # => first MyModel instance
#  myCollection.last()  # => last MyModel instance
#
#  myCollection.unsycn() # stop synchronization with server
#  myCollection.sync(3000)   # start sync every 3 second
#
#  myCollection.size() # => 3
class Sirius.Collection
  #
  # @param klass [T <: Sirius.BaseModel] - model class for all instances in collection
  # @param klasses [Array] - models, which used for `to_json` @see(Sirius.BaseModel.to_json)
  # @param options [Object] - with keys necessary
  # @param every [Numberic] - ms for remote call
  # @param on_add [Function] - callback, which will be call when add new instance to collection
  # @param on_remove [Function] - callback, which will be call when remove model from collection
  # @param remote [Function] - callback, which will be call when synchronize collection, must be return json
  constructor: (klass, klasses = [], options = {every: 0, on_add: @on_add, on_remove: @on_remove, remote: null, on_push: @on_push}) ->
    throw new Error("Collection must be used only with `BaseModel` inheritor") if klass.__super__.constructor.name isnt 'BaseModel'
    @_array = []
    @_klasses = klasses
    @_type  = klass.name

    if options.remote
      @remote = =>
        result = options.remote()
        json = JSON.parse(result)
        if Sirius.Utils.is_array(json)
          if json.length != 0
            for model in json then @push(klass.from_json(JSON.stringify(model), @_klasses))
        else
          @push(klass.from_json(result, @_klasses))

    @_timer    = null
    @_start_sync(options.every || 0)


  # @nodoc
  _start_sync: (every) ->
    if (every != 0)
      @_timer = setInterval(@remote, every)

  # stop synchronization
  unsync: () ->
    if @_timer
      clearInterval(@_timer)

  # start synchronization
  #
  # @param every [Numeric] - milliseconds
  sync: (every) ->
    @_start_sync(every)

  #
  # push model in collection
  # @param model [T <: Sirius.BaseModel]
  #
  push: (model) ->
    @_add(model)
    @on_push(model)

  # add model into collection
  # @param model [T <: Sirius.BaseModel]
  #
  add: (model) ->
    @_add(model)
    @on_add(model)

  # @nodoc  
  _add: (model) ->
    type = model.constructor.name
    throw new Error("Require `#{@_type}`, but given `#{model.constructor.name}`") if @_type isnt type
    @_array.push(model) #maybe it's a hash ? because hash have a keys, and simple remove, but need a unique id
     

  # remove model from collection
  remove: (other) ->
    inx = @index(other)
    if inx != null
      @_array.splice(inx, 1)
      @on_remove(other)

  #
  # Return index of model in collection or null, if not found
  # @param model [T <: Sirius.BaseModel]
  # @return [Numeric | null]
  index: (other) ->
    inx = null
    for model, i in @_array when model.compare(other) then inx = i
    inx

  #
  # find model by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Model | null]
  find: (key, value) ->
    @find_all(key, value)[0] || null

  #
  # find all models by key with value
  # @param key [String] - attribute
  # @param value [Any] - actual value
  # @return [Array<Model>]
  find_all: (key, value) ->
    for model in @_array when model.get(key) == value then model

  #
  # filter collection with `fn`, which must return boolean
  # @param fn [Function]
  # @return [Array<Model>]
  filter: (fn = ->) ->
    for model in @_array when fn.call(null, model) then model

  #
  # Iterate over collection with function
  # @param fn [Function]
  each: (fn = ->) ->
    for model in @_array then fn.call(model)

  # return first element in collection
  # @return [Model]
  first: () ->
    @_array[0]

  # return last element in collection
  # @return [Model]
  last: () ->
    @_array[@_array.length - 1]

  # return actual collection
  # @return [Array<Model>]
  all: () ->
    @_array

  # return size of collection
  size: () ->
    @_array.length

  # @nodoc
  on_remove: (model) ->

  # @nodoc
  on_add: (model) ->


