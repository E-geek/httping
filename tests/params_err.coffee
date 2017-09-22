{ assert } = require 'chai'
{ httping }= require '../src/httping.litcoffee'

describe 'Check type and range of parameters', ->
  describe 'interface ok', ->
    it 'two params', ->
      assert.lengthOf httping, 2
      return

  describe 'check options', ->
    it 'not a string and not an correct object: sync', ->
      fn = ->
        httping()
      assert.throws fn, TypeError, 'options is require and must be an Object
        or a String'
      for variable in [ 0, yes, undefined, null ]
        fn = ->
          httping variable
        assert.throws fn, TypeError, 'options is require and must be an Object
          or a String'
      fn = ->
        httping []
      assert.throws fn, TypeError, '`url` or `host` is required params'
      return

    it 'not a string and not an correct object: async', (done) ->
      for variable in [ 0, yes, undefined, null ]
        httping variable, (e) ->
          assert.ok e
          assert.instanceOf e, TypeError
          assert.equal e.message, 'options is require and must be an Object
            or a String'
      httping [], (e) ->
        assert.ok e
        assert.instanceOf e, TypeError
        assert.equal e.message, '`url` or `host` is required params'
        done()
      return

    it 'callback not a function', ->
      for variable in [1, 'str', null, undefined, [], {}, yes]
        fn = ->
          httping 'ya.ru', variable
        assert.throws fn, TypeError, '`callback` should be a function'
      return