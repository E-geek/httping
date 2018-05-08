{ assert } = require 'chai'
{ httping, HTTPing, HTTPEvent }= require '../src/httping.litcoffee'
{ CSEvent, CSEmitter } = require 'cstd'

describe 'Check type and range of parameters', ->
  describe 'interface ok', ->
    it 'two params', ->
      assert.lengthOf httping, 2
      return

    it 'HTTPing class', ->
      assert.isFunction HTTPing
      assert.lengthOf HTTPing, 1
      assert.isNull HTTPing::options
      return

    it 'HTTPEvent class', ->
      assert.isFunction HTTPEvent
      assert.lengthOf HTTPEvent, 1
      for prop in ['name', 'value', 'target', 'url', 'seqIdx', 'diffTime']
        assert.property HTTPEvent::, prop
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
          assert.instanceOf e, CSEvent
          assert.instanceOf e.value, TypeError
          assert.equal e.name, 'error'
          assert.equal e.value.message, 'options is require and must be an Object
            or a String'
      httping [], (e) ->
        assert.ok e
        assert.instanceOf e, CSEvent
        assert.instanceOf e.value, TypeError
        assert.equal e.name, 'error'
        assert.equal e.value.message, '`url` or `host` is required params'
        done()
      return

    it 'callback not a function', ->
      for variable in [1, 'str', null, undefined, [], {}, yes]
        fn = ->
          httping 'ya.ru', variable
        assert.throws fn, TypeError, '`callback` should be a function'
      return