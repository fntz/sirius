



class Sirisus.Collection
  #remote - ajax calls, should return json for model
  #klass Model klass, must be extend BaseModel
  constructor: (klass, klasses = [], options = {every: 0, on_add: @on_add, on_remove: @on_remove, remote: null}) ->
    throw new Error("Collection must be used only with `BaseModel` inheritor") if klass.__super__.constructor.name isnt 'BaseModel'
    @_array = []
    @_klasses = klasses
    @_type  = klass.name

    @on_add    = options.on_add || @on_add
    @on_remove = options.on_remove || @on_add

    if options.remote
      @remote = ->
        result = options.remote()
        @push(klass.from_json(result, @_klasses))
    @_timer    = null
    _start_sync(every)

  @_start_sync: (every) ->
    if (every != 0)
      @_timer = setInterval(@remote, every)


  unsync: () ->
    if @_timer
      clearInterval(@_timer)

  sync: (every) ->
    @_start_sync(every)

  #check if is instance of BaseModel
  push: (model) ->
    type = model.constructor.name
    throw new Error("Require `#{@_type}`, but given `#{model.constructor.name}`") if @_type isnt type
    @_array.push(model) #maybe it's a hash ? because hash have a keys, and simple remove, but need a unique id
    @on_add(model)

  add: (model) ->
    @push(model)

  #remove

  find: (key, value) ->
    @findAll(key, value)[0] || null

  findAll: (key, value) ->
    for model in @_array when model.get(key) == value then model

  filter: (fn = ->) ->
    for model in @_array when fn.call(null, model) then model

  each: (fn = ->) ->
    for model in @_array then fn.call(model)

  first: () ->
    @_array[0]

  last: () ->
    @_array[@_array.length - 1]

  all: () ->
    @_array

  on_remove: (model) ->

  on_add: (model) ->


