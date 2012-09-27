suite 'Identifiers', ->

  test 'reserved LiveScript words', ->
    eq 'it$$', generate new CS.Identifier 'it'
    eq 'that$$', generate new CS.Identifier 'that'
    eq 'fallthrough$$', generate new CS.Identifier 'fallthrough'
    eq 'otherwise$$', generate new CS.Identifier 'otherwise'
    eq 'where$$', generate new CS.Identifier 'where'
    eq 'xor$$', generate new CS.Identifier 'xor'
    eq 'match$$', generate new CS.Identifier 'match'
