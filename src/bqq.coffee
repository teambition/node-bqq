qs = require 'querystring'
path = require 'path'
request = require 'request'

class BQQ
  @init: (options) ->
    {@appname, @key, @secret, @ip, @start} = options
    @url = 'openapi.b.qq.com'
    @initialized = true
    return @

  @getToken: (code, state, callback) ->
    @fetch 'GET', 'oauth2/token',
      grant_type: "authorization_code"
      app_id: @key
      app_secret: @secret
      code: code
      state: state
      redirect_uri: @start
    , callback

  @authURL: -> "https://" + @url + "/oauth2/authorize?" + qs.stringify
      response_type: 'code'
      app_id: @key
      redirect_uri: @start
      state: 1

  @fetch: (method, cmd, query, callback) ->
    request
      method: method
      url: "https://#{path.join @url, cmd}?#{qs.stringify query}"
    , (err, res, body) ->
        try
          data = JSON.parse(body)
        catch e
          return callback e
        callback null, data

  constructor: (options) ->
    return unless BQQ.initialized
    {@token, @refreshToken, @companyId} = options

  baseParams: ()->
    access_token: @token
    company_id: @companyId
    app_id: BQQ.key
    client_ip: BQQ.ip
    oauth_version: 2

  companyInfo: (callback) ->
    BQQ.fetch 'GET', 'api/corporation/get', @baseParams(), callback

  memberList: (timestamp, callback = ->) ->
    if typeof timestamp is 'function'
      callback = timestamp
      timestamp = 0
    query = @baseParams()
    query.timestamp = timestamp
    BQQ.fetch 'GET', 'api/user/list', query, callback

  face: (openIds, callback) ->
    query = @baseParams()
    query.open_ids = openIds
    query.type_id = 5
    BQQ.fetch 'GET', 'api/user/face', query, callback

  email: (openIds, callback) ->
    query = @baseParams()
    query.open_ids = openIds
    BQQ.fetch 'GET', 'api/user/email', query, callback

  qq: (openIds, callback) ->
    query = @baseParams()
    query.open_ids = openIds
    BQQ.fetch 'GET', 'api/user/qq', query, callback

  tips: (params, callback = ->) ->
    {receivers, title, content, url} = params
    query = @baseParams()
    if receivers then query.receivers = receivers else query.to_all = 1
    query.window_title = BQQ.appname
    query.tips_title = title
    query.tips_content = content
    if url then query.tips_url = url
    BQQ.fetch 'POST', 'api/tips/send', query, callback

  verifyhashskey: (options, callback) ->
    params = @baseParams()
    params.open_id = options.open_id
    params.hashskey = options.hashskey
    BQQ.fetch 'GET', 'api/login/verifyhashskey', params, callback

  refresh: (callback) ->
    query =
      refresh_token: @refreshToken
      app_id: BQQ.key
      app_secret: BQQ.secret
    BQQ.fetch 'GET', 'oauth2/refresh', query, (err, data) =>
      return callback(err) if err
      return callback(data) if data.ret > 0
      data.data.old = @token
      @token = data.data.access_token
      @refreshToken = data.data.refresh_token
      callback(null, data.data)

module.exports = BQQ
