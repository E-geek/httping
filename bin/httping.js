// Generated by CoffeeScript 1.9.3
(function() {
  var help, http, httping, https, url,
    hasProp = {}.hasOwnProperty;

  help = require('./help');

  url = require('url');

  http = require('http');

  https = require('https');

  httping = function(options, callback) {
    var MAX_RECEIVE_DATA, count, escape, i, len, log, missingOptionsMessage, name, pingSender, ref, ref1, ref2, requestOptions, typeTable, value;
    if (callback == null) {
      callback = null;
    }
    if (help.checkType(options, 'string')) {
      options = {
        url: options
      };
    }
    escape = function(error) {
      if ((callback != null) && help.checkType(callback, 'function')) {
        callback({
          type: 'error',
          error: error
        });
        return;
      }
      throw error;
    };
    missingOptionsMessage = "options is require and must be an Object or a String";
    if (options == null) {
      return escape(new TypeError(missingOptionsMessage));
    }
    if (!(help.checkType(options, 'string') || options instanceof Object)) {
      return escape(new TypeError(missingOptionsMessage));
    }
    typeTable = {
      url: 'string',
      method: 'string',
      host: 'string',
      port: 'number',
      path: 'string',
      protocol: 'string',
      count: 'number',
      interval: 'number',
      timeout: 'number',
      allowErrorCode: 'boolean'
    };
    for (name in options) {
      if (!hasProp.call(options, name)) continue;
      value = options[name];
      if (typeTable[name] == null) {
        return escape(new TypeError("unknown name option: " + name));
      }
      if (!help.checkType(value, typeTable[name])) {
        return escape(new TypeError("incorrect type " + name + " option"));
      }
    }
    if (options.url != null) {
      requestOptions = url.parse(options.url);
    } else if (options.host == null) {
      return escape(new TypeError("`url` or `host` is required params"));
    } else {
      ref = ['port', 'path'];
      for (i = 0, len = ref.length; i < len; i++) {
        name = ref[i];
        requestOptions[name] = options[name];
      }
      if (options.method != null) {
        requestOptions.method = options.method.toUpperCase();
      }
      if (options.protocol) {
        requestOptions.protocol = options.protocol.toLowerCase();
      }
      requestOptions.hostname = options.host;
    }
    requestOptions.slashes = true;
    if (requestOptions.protocol == null) {
      requestOptions.protocol = 'http:';
    }
    if (requestOptions.protocol === 'http:') {
      if (requestOptions.port == null) {
        requestOptions.port = 80;
      }
    } else if (requestOptions.protocol === 'https:') {
      if (requestOptions.port == null) {
        requestOptions.port = 443;
      }
    }
    if (requestOptions.method == null) {
      requestOptions.method = 'GET';
    }
    if (requestOptions.path == null) {
      requestOptions.path = '/';
    }
    if (options.count == null) {
      options.count = 4;
    }
    if (options.interval == null) {
      options.interval = 1000;
    }
    if (options.timeout == null) {
      options.timeout = 30000;
    }
    if (options.allowErrorCode == null) {
      options.allowErrorCode = false;
    }
    if ((ref1 = requestOptions.protocol) !== 'http:' && ref1 !== 'https:') {
      return escape(new TypeError('Protocol must be "http:" or "https:"'));
    }
    if ((ref2 = requestOptions.method) !== 'GET' && ref2 !== 'POST' && ref2 !== 'OPTIONS') {
      return escape(new TypeError('Support methods: "GET", "POST", "OPTIONS"'));
    }
    if (requestOptions.port < 0 || requestOptions.port >= Math.pow(2, 16) || help.isFloat(requestOptions.port)) {
      return escape(new TypeError('Port must be between [0, 65535] and must be integer'));
    }
    if (requestOptions.count < 0 || requestOptions.count >= Math.pow(2, 32) || help.isFloat(requestOptions.count)) {
      return escape(new TypeError('Count can be 0 for endless ping or positive value less than 2^32 and must be integer'));
    }
    if (requestOptions.interval < 10 || requestOptions.interval >= Math.pow(2, 32) || help.isFloat(requestOptions.interval)) {
      return escape(new TypeError('Interval must be between [10, 2^32] and must be integer'));
    }
    if (requestOptions.timeout < 5 || requestOptions.timeout >= Math.pow(2, 32) || help.isFloat(requestOptions.timeout)) {
      return escape(new TypeError('Timeout must be between [5, 2^32] and must be integer'));
    }
    log = [];
    count = 0;
    MAX_RECEIVE_DATA = 1024 * 1024 * 10;
    pingSender = function(index) {
      return function() {
        var agent, logPush, now, req, stopReq;
        now = Date.now();
        logPush = function(code) {
          var delta, timer;
          logPush = function() {};
          delta = Date.now() - now;
          log[index] = [delta, code];
          if (++count === options.count) {
            callback(log);
            return;
          }
          timer = options.interval - delta;
          if (timer > 5) {
            help.wait(timer, pingSender(count));
          } else {
            process.nextTick(pingSender(count));
          }
        };
        stopReq = function(code, res) {
          logPush(code);
          req.abort();
          if (res != null) {
            res.destroy();
          }
        };
        help.wait(options.timeout, function() {
          stopReq(5);
        });
        if (requestOptions.protocol === 'http:') {
          agent = http;
        } else {
          agent = https;
          requestOptions.rejectUnauthorized = false;
        }
        req = agent.request(requestOptions, function(res) {
          var chunks, receiveData;
          receiveData = 0;
          chunks = [];
          if (!options.allowErrorCode && (res.statusCode > 399 || res.statusCode < 200)) {
            stopReq(1, res);
            return;
          }
          res.on('data', function(chunk) {
            chunks.push(chunk);
            receiveData += chunk.length;
            if (receiveData > MAX_RECEIVE_DATA) {
              stopReq(2, res);
              chunks = null;
            }
          }).on('end', function() {
            chunks = null;
            return logPush(0);
          });
        });
        req.on('error', function(e) {
          stopReq(3);
          console.error(e);
        }).on('abort', function() {
          stopReq(4);
        }).on('socket', function(socket) {
          socket.on('timeout', function() {
            stopReq(5);
            req.abort();
          }).setTimeout(options.timeout);
        }).write('');
        req.end();
      };
    };
    process.nextTick(pingSender(0));
    return log;
  };

  module.exports = {
    httping: httping
  };

}).call(this);
