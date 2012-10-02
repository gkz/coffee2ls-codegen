suite 'Classes', ->

  setup ->
    @x = new CS.Identifier 'x'
    @y = new CS.Identifier 'y'
    @f = new CS.Identifier 'f'
    @A = new CS.Identifier 'A'
    @B = new CS.Identifier 'B'
    @ctor = new CS.Constructor new CS.Function [], @x

  test 'super', ->
    eq 'super ...', generate new CS.Super()
    eq 'super x, y', generate new CS.Super [@x, @y]

  test 'no bodied classes', ->
    eq 'class A', generate new CS.Class @A
    eq 'class A extends B', generate new CS.Class @A, @B

  test 'simple classes', ->
    eq 'class A extends B\n  -> x\n  f: -> x',
      generate new CS.Class @A, @B, @ctor, new CS.Block [
        @ctor
        new CS.ClassProtoAssignOp @f, new CS.Function [], @x
      ]
    eq 'class A extends B\n  -> x\n  f: -> x\n  x: y',
      generate new CS.Class @A, @B, @ctor, new CS.Block [
        @ctor
        new CS.ClassProtoAssignOp @f, new CS.Function [], @x
        new CS.ClassProtoAssignOp @x, @y
      ]

