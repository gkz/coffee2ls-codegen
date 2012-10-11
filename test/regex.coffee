suite 'Regular Expressions', ->

  test 'simple regex', ->
    eq '//asdf//', generate new CS.RegExp 'asdf', []
    eq '//asdf//gi', generate new CS.RegExp 'asdf', ['g', 'i']

  test 'heregex', ->
    eq '//#{a}asdf//', generate new CS.HeregExp (new CS.ConcatOp (new CS.ConcatOp (new CS.String ''), new CS.Identifier 'a'), new CS.String 'asdf'), []
