"use strict"
Todos = []

#----------- Models ------------------#

Todos.find_by_id = (id) ->
  for t in @ when t.get("id") is id then return t  

class TodoList extends Sirius.BaseModel 
  @attrs: ["title", {completed: false}, "id"]
  @form_name : "#new-todo"
  @guid_for : "id"
  is_active: () ->
    !@get("completed")  
  
  is_completed: () -> 
    @get("completed")

Renderer =
  template: new EJS({url: 'js/todos.ejs'})  
  render: (data = []) ->
    todos = for t in data 
      klass =  if t.get("completed") 
                  "completed" 
                else 
                  ""
      {"class_name": klass, "title": t.get("title"), id: t.get("id")}
    

    template = @template.render({todos: todos})
    $("#todo-list").html("").html(template) 

#------------------ Controllers -----------------#
UrlController =
  root: () ->
    Renderer.render(Todos)
    
  active: () ->
    todos = for t in Todos when t.is_active() then t
    Renderer.render(todos)
  
  completed: () ->
    todos = for t in Todos when t.is_completed() then t
    Renderer.render(todos)
    

EventController =
  start: () ->
    Todos.push(new TodoList(
      title      : "Create a TodoMVC template"
      completed : true
    ))
    Todos.push(new TodoList(
      title: "Rule the web"
    ))
    Renderer.render(Todos)
    

  destroy: (event, id) ->
    todo = Todos.find_by_id(id)
    index = null 
    for t, i in Todos when t.get("id") == id then index = i 
    
    if index isnt null  
      Todos.splice(index, 1)
      $(event.target).parents("li").remove()
    
  mark: (event, id) ->
    todo = Todos.find_by_id(id)
    if todo.get("completed") then todo.set("completed", false) else todo.set("completed", true)
    $(event.target).parents("li").toggleClass("completed")
    
  mark_all: (event, klass) ->
    if klass == "marked"
      for t in Todos then t.set("completed", true)
    else 
      for t in Todos then t.set("completed", false)
    $(event.target).toggleClass("marked")
    Renderer.render(Todos)
  
  is_enter: (event) ->
    return true if event.which == 13
    false
    
  new_todo: (event) ->
    new_todo = TodoList.from_html()
    console.log new_todo
    Todos.push new_todo
    Renderer.render(Todos)
    $("#new-todo").val('')
  
  update_footer: () ->
    if Todos.length == 0
      $("#footer").hide()
      return 
    else
      $("#footer").show()  
    
    active    = (for _ in Todos when _.is_active() then _).length
    completed = (for _ in Todos when _.is_completed() then _).length
    
    $("#todo-count strong").text(active)

    if completed > 0
      $("#clear-completed").show()
      $("#clear-completed").text("Clear completed (#{completed})")
    else
      $("#clear-completed").hide()

  edit: (e) ->
    $(e.target).parents("li").addClass("editing")
    $(e.target).children(".edit").focus()

  update: (e, id) ->
    trg = $(e.target)
    todo = Todos.find_by_id(id)
    todo.set("title", trg.val())
    trg.val('')
    trg.parents("li").toggleClass("editing")
    Renderer.render(Todos)

  clear: (e) ->
    xs = for t, i in Todos when t.is_completed() then i 
    for i in xs then Todos.splice(i, 1)
    Renderer.render(Todos)

# ----------------------- Routing ----------------- #

routes = 
  "#"               : {controller: UrlController, action: "root"}
  "#/active"        : {controller: UrlController, action: "active"}
  "#/completed"     : {controller: UrlController, action: "completed"}
  "application:run" : {controller: EventController, action: "start"}
  "click button.destroy"  : {controller: EventController, action: "destroy", after: "update_footer", data: "data-id"}
  "click li input.toggle" : {controller: EventController, action: "mark", after: "update_footer", data: "data-id"}
  "click #toggle-all"     : {controller: EventController, action: "mark_all", after: "update_footer", data: "class"} 
  "keypress #new-todo"    : {controller: EventController, action: "new_todo", guard: "is_enter", after: "update_footer"}
  "dblclick li": {controller: EventController, action: "edit"} 
  "keypress input.edit": {controller: EventController, action: "update", data: "data-id", guard: "is_enter"}
  "click #clear-completed": {controller: EventController, action: "clear", after: "update_footer"}

# ----------------------- Start -------------------- #

$ ->
  app = Sirius.Application.run
    route   : routes
    adapter : new JQueryAdapter()
    start   : "#"







