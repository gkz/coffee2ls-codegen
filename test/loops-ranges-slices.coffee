suite 'Loop, Ranges, and Slices', ->

  setup ->
    @zero = new CS.Int 0
    @one = new CS.Int 1
    @two = new CS.Int 2

    @true = new CS.Bool true

    @x = new CS.Identifier 'x'
    @y = new CS.Identifier 'y'
    @xs = new CS.Identifier 'xs'
    @ys = new CS.Identifier 'ys'

    @blk = new CS.Block [@x]

  test 'simple range', ->
    eq '[1 to 2]', generate new CS.Range true, @one, @two
    eq '[1 til 2]', generate new CS.Range false, @one, @two

  test 'simple slice', ->
    eq 'x[1 to 2]', generate new CS.Slice @x, true, @one, @two
    eq 'x[1 til 2]', generate new CS.Slice @x, false, @one, @two

  test 'for in loop', ->
    eq 'for x in xs\n  x',
      generate new CS.ForIn @x, null, @xs, @one, null, @blk
    eq 'for x, y in xs\n  x',
      generate new CS.ForIn @x, @y, @xs, @one, null, @blk
    eq 'for x in xs by 2\n  x',
      generate new CS.ForIn @x, null, @xs, @two, null, @blk
    eq 'for x in xs when true\n  x',
      generate new CS.ForIn @x, null, @xs, @one, @true, @blk
    eq 'for x, y in xs by 2 when true\n  x',
      generate new CS.ForIn @x, @y, @xs, @two, @true, @blk

  test 'for in loop with range target', ->
    eq 'for x from 1 to 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range true, @one, @two), @one, null, @blk
    eq 'for x from 1 til 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range false, @one, @two), @one, null, @blk
    eq 'for x to 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range true, @zero, @two), @one, null, @blk
    eq 'for x til 2\n  x',
      generate new CS.ForIn @x, null,
        (new CS.Range false, @zero, @two), @one, null, @blk

  test 'for of loop', ->
    eq 'for x of xs\n  x',
      generate new CS.ForOf false, @x, null, @xs, null, @blk
    eq 'for own x of xs\n  x',
      generate new CS.ForOf true, @x, null, @xs, null, @blk
    eq 'for x, y of xs\n  x',
      generate new CS.ForOf false, @x, @y, @xs, null, @blk
    eq 'for x of xs when true\n  x',
      generate new CS.ForOf false, @x, null, @xs, @true, @blk
    eq 'for own x, y of xs when true\n  x',
      generate new CS.ForOf true, @x, @y, @xs, @true, @blk

  test 'for loops with different bodies', ->
    eq 'for x in xs\n  void',
      generate new CS.ForIn @x, null, @xs, @one, null
    eq 'for x in xs\n  x\n  y',
      generate new CS.ForIn @x, null, @xs, @one, null, new CS.Block [@x, @y]
    eq 'x = for x in xs\n  x\n  y',
      generate new CS.AssignOp @x,
        (new CS.ForIn @x, null, @xs, @one, null, new CS.Block [@x, @y])

  test 'comprehensions', ->
    eq 'x = [x for x in xs]',
      generate new CS.AssignOp @x,
        (new CS.ForIn @x, null, @xs, @one, null, @blk)
    eq 'x = [x for x of xs]',
      generate new CS.AssignOp @x,
        (new CS.ForOf false, @x, null, @xs, null, @blk)

  test 'nested loops when used as an expresison', ->
    eq '',
      generate new CS.AssignOp @z,
        (new CS.ForIn @x, null, @xs, @one, null, new CS.Block [
          new CS.ForIn @y, null, @ys, @one, null, new CS.Block [
            new CS.PlusOp @x, @y
          ]
        ])

  test 'nested loops', ->


  test 'while loop', ->
    eq 'while true\n  x', generate new CS.While @true, @blk

  test 'break', ->
    eq 'break', generate new CS.Break()

  test 'continue', ->
    eq 'continue', generate new CS.Continue()
