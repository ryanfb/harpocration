$(document).ready ->
  mock_access_token_params =
    access_token: 'nonsense'
    expires_in: 3600
    token_type: 'Bearer'

  test "hello test", ->
    ok( 1 == 1, "Passed!" )

  test "URN construction", ->
    equal( cite_urn('namespace','collection','row'), 'urn:cite:namespace:collection.row' )
    equal( cite_urn('namespace','collection','row','version'), 'urn:cite:namespace:collection.row.version' )

  module "cookie functions"

  test "values set by set_cookie should be readable by get_cookie", ->
    set_cookie 'cookie_test', 'test value', 60
    equal( get_cookie('cookie_test'), 'test value' )
    delete_cookie 'cookie_test'

  test "values deleted by delete_cookie should return null", ->
    set_cookie 'delete_cookie_test', 'test value', 60
    delete_cookie 'delete_cookie_test'
    equal( get_cookie('delete_cookie_test'), null )

  asyncTest "cookies set by set_cookie should expire", ->
    expect(2)
    set_cookie 'expire_cookie_test', 'test value', 1
    equal( get_cookie('expire_cookie_test'), 'test value' )
    setTimeout ->
      equal( get_cookie('expire_cookie_test'), null )
      start()
    , 1001

  module "access token cookies",
    setup: ->
      delete_cookie 'access_token'
    teardown: ->
      delete_cookie 'access_token'
      $.mockjaxClear()

  test "access token cookie should not be written for invalid access tokens", ->
    expect(2)
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
    expect(2)
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

  module "author name",
    setup: ->
      set_cookie 'access_token', 'nonsense', 3600
      delete_cookie 'author_name'
      $('.container').append $('<input>').attr('id','Author').attr('value','')
    teardown: ->
      delete_cookie 'access_token'
      delete_cookie 'author_name'
      $('#Author').remove()
      $.mockjaxClear()

  test "set_author_name should pull from cookie when available", ->
    equal( $('#Author').attr('value'), '', 'author empty at start')
    set_cookie 'author_name', 'Test User', 60
    set_author_name()
    equal( $('#Author').attr('value'), 'Test User', 'author set')

  test "set_author_name with a successful AJAX call should set the cookie and populate the UI", ->
    expect(3)
    equal( $('#Author').attr('value'), '', 'author empty at start')
    $.mockjax
      url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
      contentType: 'text/json'
      status: 200
      responseText:
        name: 'AJAX User'
    stop()
    set_author_name ->
      equal( get_cookie('author_name'), 'AJAX User' )
      equal( $('#Author').attr('value'), 'AJAX User' )
      start()

  test "set_author_name with an unsuccessful AJAX call should do nothing", ->
    expect(3)
    equal( $('#Author').attr('value'), '', 'author empty at start')
    $.mockjax
      url: 'https://www.googleapis.com/oauth2/v1/userinfo?*'
      contentType: 'text/json'
      responseText:
        error: "invalid_token"
      status: 400
    stop()
    set_author_name ->
      equal( get_cookie('author_name'), null )
      equal( $('#Author').attr('value'), '' )
      start()

  module "filter url",
    setup: ->
      history.replaceState(null,'',window.location.href.replace("#{location.hash}",''))
    teardown: ->
      history.replaceState(null,'',window.location.href.replace("#{location.hash}",''))

  test "filter_url_params should filter off access_token, expires_in, and token_type by default", ->
    clean_url = window.location.href.replace("#{location.hash}",'')
    equal( window.location.href, clean_url, "url is clean at test start" )
    history.replaceState(null,'',"#{window.location.href}##{$.param(mock_access_token_params)}")
    equal( window.location.href, "#{clean_url}##{$.param(mock_access_token_params)}", "url gets expected parameters at test start" )
    original_params = parse_query_string()
    filtered_params = filter_url_params(original_params)
    equal( filtered_params, original_params, "filter_url_params returns original params" )
    equal( window.location.href, clean_url, "filter_url_params strips off expected params" )

  test "filter_url_params should filter off passed in parameters", ->
    clean_url = window.location.href.replace("#{location.hash}",'')
    equal( window.location.href, clean_url, "url is clean at test start" )
    collection_param =
      collection: 'nonsense'
    history.replaceState(null,'',"#{window.location.href}##{$.param(collection_param)}")
    equal( window.location.href, "#{clean_url}##{$.param(collection_param)}", "url gets expected parameters at test start" )
    original_params = parse_query_string()
    filtered_params = filter_url_params(original_params,['collection'])
    equal( filtered_params, original_params, "filter_url_params returns original params" )
    equal( window.location.href, clean_url, "filter_url_params strips off expected params" )
