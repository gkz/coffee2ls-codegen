suite 'Other Literals', ->

  test 'undefined -> void', ->
    eq 'void', generate new CS.Undefined()
