
Utils =
  fire: () ->
    Sirius.Application.get_adapter().and_then (adapter) ->
      adapter.fire(document, 'collection:change')