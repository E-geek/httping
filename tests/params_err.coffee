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
      fn = ->
        httping 12
      assert.throws fn, TypeError, 'options is require and must be an Object
        or a String'
      fn = ->
        httping []
      assert.throws fn, TypeError, '`url` or `host` is required params'