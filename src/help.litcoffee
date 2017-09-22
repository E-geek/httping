## Helpers for HTTPing

Export a help methods of module.

    module.exports = help =

This method is used to check the type of the variable `variable`
for a `type` match

      checkType: (variable, type) ->
        if /[a-z]/.test type.charAt(0)
          type = type.charAt(0).toUpperCase() + type.substr 1
        return "[object #{type}]" is Object::toString.call variable

Check value for floating point exists

      isFloat: (num) ->
        if not help.checkType num, 'number'
          return no
        return Math.round(num) isnt num

Wait is classic function for coffee

      wait: (time, fn) -> setTimeout fn, time
