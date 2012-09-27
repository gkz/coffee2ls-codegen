suite 'Unsupported', ->

  test 'JavaScript literals', ->
    try
      generate new CS.JavaScript '1 + 1'
    catch e
      eq 'LiveScript does not support JavaScript literals', e.message
