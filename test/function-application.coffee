suite 'Function Application', ->

  setup ->
    @f = new CS.Identifier 'f'
    @a = new CS.Identifier 'a'
    @b = new CS.Identifier 'b'

  test 'function application against implicit object', ->
    eq 'f {\n  a: b\n  b: a\n  f: a\n}',
      generate new CS.FunctionApplication @f, [
        new CS.ObjectInitialiser [
          (new CS.ObjectInitialiserMember @a, @b),
          (new CS.ObjectInitialiserMember @b, @a),
          (new CS.ObjectInitialiserMember @f, @a)
        ]
      ]
