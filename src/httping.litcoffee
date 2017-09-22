# HTTPing

HTTPing is an analog of the UNIX utility httping for Node.JS.
It is the single object with a methods for check a HTTP(S) server is
(un)avialable. We can create the instance with settings for rerun or
run one execute.

First. We require internal instruments and connection module.

    help = require './help'

    url = require 'url'
    http = require 'http'
    https = require 'https'

This is the provider to HTTPing class. Argument `options` is a require.
Argument `callback` not require and if it missing, need setup listeners
to the events 'all', 'ok', 'fail'. Callback take the argument `Event`.

    httping = (options, callback = null) ->
      if help.checkType options, 'string'
        options = { url: options }

Options possible:

* **`url`** `string` is a URL for check ping
* **`method`** `string` is a HTTP request method. Possible: `GET`, `POST`, `OPTIONS` (*by default* is `GET`)
* **`host`** `string` is a hostname without protocol and path (domain name or IP)
* **`port`** `number` is a port of service (*by default* is `80` for non-ssl and `443` for ssl)
* **`path`** `string` is a pathname for request (*by default* is '/')
* **`protocol`** `string` is a enum `http:` or `https:` for SSL connections
* **`count`** `number` how many times to ping, if 0 then endless ping (can be stop by method `stop`), (*by default* is 4)
* **`interval`** `number` delay between each ping in ms, *by default* is `1000`
* **`timeout`** `number` timeout in ms (*by default* is 30000)
* **`allowErrorCode`** `boolean` 4xx and 5xx response code is correct (*by default* no)

Check callback type

      if arguments.length >= 2 and not help.checkType callback, 'function'
        throw new TypeError "`callback` should be a function"

Break from create HTTPing if arguments broken function

      escape = (error) ->
        if callback? and help.checkType callback, 'function'
          callback error
          return
        throw error
        return

      missingOptionsMessage = "options is require and must be an Object
          or a String"
      if not options?
        return escape new TypeError missingOptionsMessage
      unless help.checkType(options, 'string') or options instanceof Object
        return escape new TypeError missingOptionsMessage

Create table of types for check options

      typeTable =
        url: 'string'
        method: 'string'
        host: 'string'
        port: 'number'
        path: 'string'
        protocol: 'string'
        count: 'number'
        interval: 'number'
        timeout: 'number'
        allowErrorCode: 'boolean'

And check every option to right type. It is need for prevent error on call
interface. Every param must be normal type.

      for own name, value of options
        unless typeTable[name]?
          return escape new TypeError "unknown name option: #{name}"
        if not help.checkType value, typeTable[name]
          return escape new TypeError "incorrect type #{name} option"

Parse url and fill params or use params from options with check types

      if options.url?
        requestOptions = url.parse options.url
      else if not options.host?
        return escape new TypeError "`url` or `host` is required params"
      else
        for name in ['port', 'path']
          requestOptions[name] = options[name]
        if options.method? # correct case dual mode
          requestOptions.method = options.method.toUpperCase()
        if options.protocol # correct case dual mode
          requestOptions.protocol = options.protocol.toLowerCase()
        requestOptions.hostname = options.host

Fill request options by default if not set yet

      requestOptions.slashes = yes
      requestOptions.protocol ?= 'http:'
      if requestOptions.protocol is 'http:'
        requestOptions.port ?= 80
      else if requestOptions.protocol is 'https:'
        requestOptions.port ?= 443
      requestOptions.method ?= 'GET'
      requestOptions.path ?= '/'

Fill similar options by default

      options.count ?= 4
      options.interval ?= 1000
      options.timeout ?= 30000
      options.allowErrorCode ?= no

Check enums (protocol and method) and range (port, timeout, interval and count)

      if requestOptions.protocol not in ['http:', 'https:']
        return escape new TypeError 'Protocol must be "http:" or "https:"'

      if requestOptions.method not in ['GET', 'POST', 'OPTIONS']
        return escape new TypeError 'Support methods: "GET", "POST", "OPTIONS"'

      if requestOptions.port < 0 or requestOptions.port >= 2**16 or
        help.isFloat requestOptions.port
          return escape new TypeError 'Port must be between [0, 65535] and \
            must be integer'

      if requestOptions.count < 0 or requestOptions.count >= 2**32 or
        help.isFloat requestOptions.count
          return escape new TypeError 'Count can be 0 for endless ping or \
            positive value less than 2^32 and must be integer'

      if requestOptions.interval < 10 or requestOptions.interval >= 2**32 or
        help.isFloat requestOptions.interval
          return escape new TypeError 'Interval must be between [10, 2^32] and \
            must be integer'

      if requestOptions.timeout < 5 or requestOptions.timeout >= 2**32 or
        help.isFloat requestOptions.timeout
          return escape new TypeError 'Timeout must be between [5, 2^32] and \
            must be integer'

If all data is correct, we can set start values (log, time, counter) and run ping
Log format: [ [time, code], ... ] if good is good

      log = []
      count = 0
      MAX_RECEIVE_DATA = 1024*1024*10

Method for send request have a time point a start and function logPush for add
message to log and prevend dual set data

      pingSender = (index) -> ->

        now = Date.now()

        logPush = (code) ->
          logPush = ->
          delta = Date.now() - now
          log[index] = [delta, code]
          if ++count is options.count
            callback log
            return
          timer = options.interval - delta
          if timer > 5
            help.wait timer, pingSender(count)
          else
            process.nextTick pingSender(count)
          return

        stopReq = (code, res) ->
          logPush code
          req.abort()
          res.destroy() if res?
          return

        help.wait options.timeout, ->
          stopReq 5 # timeout
          return

        if requestOptions.protocol is 'http:'
          agent = http
        else
          agent = https
          requestOptions.rejectUnauthorized = no
        req = agent.request requestOptions, (res) ->
          receiveData = 0
          chunks = []
          if not options.allowErrorCode and
            (res.statusCode > 399 or res.statusCode < 200)
              stopReq 1, res # error code
              return
          res.on 'data', (chunk) ->
            chunks.push chunk
            receiveData += chunk.length
            if receiveData > MAX_RECEIVE_DATA
              stopReq 2, res # error too much data
              chunks = null
            return
          .on 'end', ->
            chunks = null
            logPush 0 # success
          return

        req
        .on 'error', (e) ->
          stopReq 3 # error any error
          console.error e
          return
        .on 'abort', ->
          stopReq 4 # error abort
          return
        .on 'socket', (socket) ->
          socket
            .on 'timeout', ->
              stopReq 5 # timeout
              req.abort()
              return
            .setTimeout options.timeout
          return # e:socket
        .write ''
        req.end()
        return # pingSenderHandler

      process.nextTick pingSender 0
      return log

Export this function

    module.exports = { httping }