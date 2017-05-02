
TodoController =

  is_enter: (custom_event, original_event) ->
    return true if original_event.which == 13
    false

  create: (custom_event, original_event, model) ->
    todo = new Task(title: model.title())
    TodoList.add(todo)

  clear_input: () ->
    $(HtmlElements.new_todo).val("")

  mark_all: (e, state) ->
    if state == 'completed'
      TodoList.filter((t) -> t.is_completed()).map((t) -> t.renew())
    else
      TodoList.filter((t) -> t.is_active()).map((t) -> t.cancel())

    $(HtmlElements.toggle_all).toggleClass('completed')


  destroy: (e, id) ->
    todo = TodoList.filter((t) -> t.id() == id)[0]
    TodoList.remove(todo)

    Utils.fire()