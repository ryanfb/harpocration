mock_access_token_params =
  access_token: 'nonsense'
  expires_in: 3600
  token_type: 'Bearer'

test "hello test", ->
  ok( 1 == 1, "Passed!" )

test "URN construction", ->
  equal( cite_urn('namespace','collection','row'), 'urn:cite:namespace:collection.row' )
  equal( cite_urn('namespace','collection','row','version'), 'urn:cite:namespace:collection.row.version' )

module "access token cookies",
  setup: ->
    set_cookie 'access_token', 'delete', -86400
  teardown: ->
    set_cookie 'access_token', 'delete', -86400
    $.mockjaxClear()

test "access token cookie should not be written for invalid access tokens", ->
  equal( get_cookie('access_token'), null, 'cookie not set at test start' )
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/tokeninfo?*'
    contentType: 'text/json'
    responseText:
      error: "invalid_token"
    status: 400
  stop()
  set_access_token_cookie mock_access_token_params, ->
    equal( get_cookie('access_token'), null )
    start()

test "access token cookie should be written for valid access tokens", ->
  equal( get_cookie('access_token'), null, 'cookie not set at test start' )
  $.mockjax
    url: 'https://www.googleapis.com/oauth2/v1/tokeninfo?*'
    contentType: 'text/json'
    responseText:
      audience: 'nonsense'
      user_id: 'nonsense'
      scope: 'nonsense'
      expires_in: 3600
    status: 200
  stop()
  set_access_token_cookie mock_access_token_params, ->
    equal( get_cookie('access_token'), mock_access_token_params['access_token'] )
    start()
