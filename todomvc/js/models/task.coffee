
class Task extends Sirius.BaseModel
  @attrs: ["title", {completed: false}, "id"]

  constructor: (obj = {}) ->
    super(obj)
    @_id = "todo-#{Math.random().toString(36).substring(7)}"

  is_active: () -> !@is_completed()

  is_completed: () -> @completed()

  cancel: () -> @completed(true)
  renew: () -> @completed(false)

  after_update: (attribute, newvalue, oldvalue) ->
    if attribute == "completed"
      Utils.fire()

  compare: (other) -> other.id() == @id()

  toString: () ->
    "Todo[id=#{@id()}, title=#{@title()}, completed=#{@completed()}]"