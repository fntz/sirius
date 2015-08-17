"use strict"

`var c = function(m){console.log(m);};`

class Task extends Sirius.BaseModel
  @attrs: ["title", completed: {completed: false}, "id"]

  constructor: (obj = {}) ->
    super(obj)
    @_id = "todo-#{Math.random().toString(36).substring(7)}"

  is_active: () -> !@is_completed()
  
  is_completed: () -> @completed().completed

  cancel: () -> @completed({completed: true})
  renew: () -> @completed({completed: false})

  after_update: (attribute, newvalue, oldvalue) ->
    if attribute == "completed"
      Sirius.Application.get_adapter().and_then (adapter) ->
        adapter.fire(document, "collection:change")

  compare: (other) -> other.id() == @id()

  toString: () ->
    "Todo[id=#{@id()}, title=#{@title()}, completed=#{@completed().completed}]"

Renderer =
  todo_template: new EJS({url: 'js/todo.ejs'})
  view: new Sirius.View("#todo-list")
  clear_view: new Sirius.View("#clear-completed", (size) -> "Clear completed (#{size})")

  render: (todo_list) ->
    @view.render().clear()
    for todo in todo_list
      @append(todo)

  append: (todo) ->
    template = @todo_template.render({todo: todo})
    @view.render(template).append()
    id = "li\##{todo.id()}"

    todo_view = new Sirius.View(id)

    todo.bind(todo_view, {
      "#{id}": {
        from: "completed",
        to: "class",
        transform: (t) ->
          if t.completed then "completed" else ""
      }
      "input[type='checkbox']": {from: "completed", to: "checked"}
      "label": {from: "title"}
    })

    todo_view.bind(todo, {
      ".view input": {from: "checked", to: "completed"}
      "input.edit": {to: "title"}
    })

    todo_view.on('div', 'dblclick', (x) ->
      todo_view.render("editing").swap('class')
    )
    return

  clear: (size) ->
    if size != 0
      @clear_view.render(size).swap()
    else
      @clear_view.render().clear()


TodoList = new Sirius.Collection(Task)

TodoList.subscribe('add', (todo) -> Renderer.append(todo))
TodoList.subscribe('remove', (todo) -> $("\##{todo.id()}").remove())



#------------------ Controllers -----------------#

MainController =
  root: () ->
    Renderer.render(TodoList.all())

  active: () ->
    Renderer.render(TodoList.filter((t) -> t.is_active()))

  completed: () ->
    Renderer.render(TodoList.filter((t) -> t.is_completed()))

  start: () ->
    view  = new Sirius.View("#todoapp")
    model = new Task()
    view.bind(model, {
      "#new-todo": {to: "title"}
    })
    model.bind(view, {
      "#new-todo": {from: "title"}
    })
    view.on("#new-todo", "keypress", "todo:create", model)

    length_view = new Sirius.View("#todo-count strong")
    length_view.bind(TodoList, 'length')

    footer = new Sirius.View("#footer")
    footer.bind(TodoList, 'length', {
      to: 'class'
      transform: (x) ->
        if x == 0
          "hidden"
        else
          ""
    })
    TodoList.add(new Task({title : "Create a TodoMVC template", completed: {completed: true}}))
    TodoList.add(new Task(title: "Rule the web"))


TodoController =

  is_enter: (custom_event, original_event) ->
    return true if original_event.which == 13
    false

  create: (custom_event, original_event, model) ->
    todo = new Task(title: model.title())
    TodoList.add(todo)
    model.title("")


  mark_all: (e, state) ->
    if state == 'completed'
      TodoList.filter((t) -> t.is_completed()).map((t) -> t.renew())
    else
      TodoList.filter((t) -> t.is_active()).map((t) -> t.cancel())

    $("#toggle-all").toggleClass('completed')


  destroy: (e, id) ->
    todo = TodoList.filter((t) -> t.id() == id)[0]
    TodoList.remove(todo)

BottomController =
  change: (ev) ->
    Renderer.clear(TodoList.filter((t) -> t.is_completed()).length)


  clear: () ->
    TodoList.filter((t) -> t.is_completed()).map((t) -> TodoList.remove(t))
    Renderer.clear(0)


LinkController =
  url: (event, current, prev) ->
    prev = if prev == "" then "/" else prev
    document.querySelector("a[href='#{current}']").className = "selected"
    document.querySelector("a[href='#{prev}']").className = ""


# ----------------------- Routing ----------------- #

routes = 
  "/"               : {controller: MainController, action: "root"}
  "/active"        :  {controller: MainController, action: "active"}
  "/completed"     :  {controller: MainController, action: "completed"}
  "application:run" : {controller: MainController, action: "start"}
  "todo:create" :     {controller: TodoController, action: "create", guard: "is_enter"}
  "application:urlchange": {controller: LinkController, action: "url"}
  "click #toggle-all"     : {controller: TodoController, action: "mark_all", data: 'class'}
  "collection:change" : {controller: BottomController, action: "change"}
  "click button.destroy"  : {controller: TodoController, action: "destroy", data: "data-id"}
  "click #clear-completed": {controller: BottomController, action: "clear"}

# ----------------------- Start -------------------- #

$ ->
  Sirius.Application.run
    route   : routes
    adapter : new JQueryAdapter()
    log: false
    log_filters: [0]








