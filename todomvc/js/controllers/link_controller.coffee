
LinkController =
  url: (event, current, prev) ->
    prev = if prev == '' then '/' else prev
    document.querySelector("a[href='#{current}']").className = 'selected'
    document.querySelector("a[href='#{prev}']").className = ''