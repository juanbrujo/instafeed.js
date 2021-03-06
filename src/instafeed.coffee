class Instafeed
  constructor: (params) ->
    # default options
    @options =
      target: 'instafeed'
      get: 'popular'
      resolution: 'thumbnail'
      links: true
      limit: 15

    # if an object is passed in, override the default options
    if typeof params is 'object'
      @options[option] = value for option, value of params

  # MAKE IT GO!
  run: ->
    # make sure either a client id or access token is set
    if typeof @options.clientId isnt 'string'
      unless typeof @options.accessToken is 'string'
        throw new Error "Missing clientId or accessToken."
    if typeof @options.accessToken isnt 'string'
      unless typeof @options.clientId is 'string'
        throw new Error "Missing clientId or accessToken."

    # make a new script element
    script = document.createElement 'script'

    # give the script an id so it can removed later
    script.id = 'instafeed-fetcher'

    # assign the script src using _buildUrl()
    script.src = @_buildUrl()

    # add the new script object to the header
    header = document.getElementsByTagName 'head'
    header[0].appendChild script

    # create a global object to cache the options
    window.instafeedCache = new Instafeed @options

    # return true if everything ran
    true

  # Data parser (must be a json object)
  parse: (response) ->
    # throw an error if not an object
    if typeof response isnt 'object'
      throw new Error 'Invalid JSON response'

    # check if the api returned an error code
    if response.meta.code isnt 200
      throw new Error "Problem parsing response: #{response.meta.error_message}"

    # check if the returned data is empty
    if response.data.length is 0
      throw new Error "No images were returned from Instagram"

    # create a new html fragment
    fragment = document.createDocumentFragment()

    # limit the number of images if needed
    images = response.data
    images = images[0..@options.limit] if images.length > @options.limit

    # loop through the images
    for image in images
      # create the image using the @options's resolution
      img = document.createElement 'img'
      img.src = image.images[@options.resolution].url

      # wrap the image in an anchor tag, unless turned off
      if @options.links is true
        # create an anchor link
        anchor = document.createElement 'a'
        anchor.href = image.link

        # add the image to it
        anchor.appendChild img

        # add the anchor to the fragment
        fragment.appendChild anchor
      else
        # add the image (without link) to the fragment
        fragment.appendChild img

    # Add the fragment to the DOM
    document.getElementById(@options.target).appendChild fragment

    # remove the injected script tag
    header = document.getElementsByTagName('head')[0]
    header.removeChild document.getElementById 'instafeed-fetcher'

    # delete the cached instance of the class
    delete window.instafeedCache

    # return true if everything ran
    true

  # helper function that structures a url for the run()
  # function to inject into the document hearder
  _buildUrl: ->
    # set the base API URL
    base = "https://api.instagram.com/v1"

    # get the endpoint based on @options.get
    switch @options.get
      when "popular" then endpoint = "media/popular"
      when "tagged"
        # make sure a tag is defined
        if typeof @options.tagName isnt 'string'
          throw new Error "No tag name specified. Use the 'tagName' option."

        # set the endpoint
        endpoint = "tags/#{@options.tagName}/media/recent"

      when "location"
        # make sure a location id is defined
        if typeof @options.locationId isnt 'number'
          throw new Error "No location specified. Use the 'locationId' option."

        # set the endpoint
        endpoint = "locations/#{@options.locationId}/media/recent"

      when "user"
        # make sure there is a user id set
        if typeof @options.userId isnt 'number'
          throw new Error "No user specified. Use the 'userId' option."

        # make sure there is an access token
        if typeof @options.accessToken isnt 'string'
          throw new Error "No access token. Use the 'accessToken' option."

        endpoint = "users/#{@options.userId}/media/recent"
      # throw an error if any other option is given
      else throw new Error "Invalid option for get: '#{@options.get}'."

    # build the final url (uses the instance name)
    final = "#{base}/#{endpoint}"

    # use the access token for auth when it's available
    # otherwise fall back to the client id
    if @options.accessToken?
      final += "?access_token=#{@options.accessToken}"
    else
      final += "?client_id=#{@options.clientId}"

    # add the count limit
    final += "&count=#{@options.limit}"

    # add the jsonp callback
    final += "&callback=instafeedCache.parse"

    # return the final url
    final

# set up exports
root = exports ? window
root.Instafeed = Instafeed
