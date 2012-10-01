suite 'Loop, Ranges, and Slices', ->

  setup ->
    @one = new CS.Int 1
    @two = new CS.Int 2

  test 'simple range', ->
    eq '[1 to 2]', generate new CS.Range true, @one, @two
    eq '[1 til 2]', generate new CS.Range false, @one, @two
