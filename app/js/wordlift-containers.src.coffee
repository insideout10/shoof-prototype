
# Define the Wordlift Containers Engine
# Here is the core logic for containers rendering engine
# Skins are managed as separated modules
angular.module("wordlift.containers.engine", ["geolocation"])

# Define a custom storageProvider used to inject 
# window.containers within the app boot / configuration
.provider("storage", () ->
  containers = undefined
  return {
    setContainers: (cnts) ->
      containers = cnts
    $get: () ->
      return {
          containers: containers
      }
  }
)
# Provide configuration for the app, depending from in page containers
.config((storageProvider) ->
  storageProvider.setContainers window.containers
)
# wlContainersCtrl manage communications between 
# wlContainer directives, ContextManagerService and DataRetriverService
.controller("wlContainersEngineCtrl", [
  "ContextManagerService"
  "DataRetrieverService"
  "$scope"
  "$rootScope"
  "$log"
  "storage"
  "geolocation"
  (ContextManagerService, DataRetrieverService, $scope, $rootScope, $log, storage, geolocation) ->
    
    $scope.stack = {}    
    $scope.observers = {}    
    
    # Retrieve coords for corrent user and pass them to ContextManager
    geolocation.getLocation().then (data) ->
      $log.info "User location detected: longitude #{data.coords.longitude} latitude #{data.coords.latitude}"
      ContextManagerService.addUserProperty "lat", data.coords.latitude
      ContextManagerService.addUserProperty "lng", data.coords.longitude  
      $scope.updateStack()  

    $scope.context = ContextManagerService.getContext()
    
    for uri, ctn of storage.containers
       $scope.stack[uri] = uri

    # Reset the page stack
    $scope.resetStack = ()->
      for id, origin of $scope.stack  
        $scope.stack[id] = id
    # Update the page stack
    $scope.updateStack = ()->
      for id, origin of $scope.stack    
        newOrigin = ContextManagerService.rewriteOrigin id, $scope.observers[id]
        $scope.stack[id] = newOrigin

    # Everytime the context changes the stack need to be update accordingly
    $rootScope.$on "notifyUserInteraction", (event, action, item) ->
        ContextManagerService.trackUserInteraction action, item
        $log.info "Context updated! Let's update the page stack accordingly!"
        $scope.updateStack()

    $rootScope.$on "containerAdded", (event, ctnOrigin, ctnObserver) ->
      $log.debug "Added ctn #{ctnOrigin} reactive to #{ctnObserver}"
      $scope.stack[ctnOrigin] = ctnOrigin
      $scope.observers[ctnOrigin] = ctnObserver
])
# Represents and manage the Context
# The context is made up a set of key / value properties
# @_allowedProperties define which properties are allowed within the context definition
# The current context can be outputed as a querystring fragment
# Append this fragment to an existing uri means 
# to apply a context to an existing container, genereting a new container reference 
.service("ContextManagerService", [
  "$log", 
  "$window",
  ($log, $window) ->
    
    service =
      _context: 
        userProperties: []
        userInteractions: {}
    # Returns the current context
    service.getContext = ->
      @_context
    
    # Add user propertiy  
    service.addUserProperty = (k, v)->   
      @_context.userProperties.push [ k, v ]   
    
    # Track a user interaction  
    service.trackUserInteraction = (action, item)->   
      @_context.userInteractions = {
        'action': action, 
        'item': item 
      }  

      # notify the action trough a GA event
      # https://developers.google.com/analytics/devguides/collection/analyticsjs/events?hl=it
      $log.debug "Going to notify userInteraction to analytics!"
      $window.ga? "send", "event", "userInteraction", action, item.id
      true

    # Rewrite origin means append the context to the origin
    # The oupput is a new container reference
    service.rewriteOrigin = (origin, observers)->
      
      chunks = []
      # if react to user properties ...
      if "userProperties" in observers
        for property in @_context.userProperties
          chunks.push property.join('=')
      # if react to user interaction ...
      if "userInteractions" in observers and @_context.userInteractions.item      
        chunks.push [ "contentId", @_context.userInteractions.item.id ].join('=')
      
      if chunks.length > 0
        # TODO Adapt to a real querystring
        origin = origin.replace ".json", "---#{chunks.join('&')}.json"
        return origin
      
      origin
      
    # Reset the context    
    service.resetContext = ()->
      @_context = {}

    service
])
# Data retrieving specilized service
# Store containers content in @_containers
# If a data structure is missing try to load from remote
.service("DataRetrieverService", [
  "$http",
  "$log",
  "$rootScope",
  "$q"
  "storage"
  ($http, $log, $rootScope, $q, storage) ->
    
    service = 
      _containers: storage.containers
    
    service.prepareHttpRequest = (ctnOrigin)->
      config = 
        url: ctnOrigin
        method: 'GET'
        #responseType: 'json'

      if /^(http|https):\/\//.test ctnOrigin
        config.method = 'JSONP'
        config.params = { callback: "JSON_CALLBACK" }

      $log.info "Going to request #{ctnOrigin} with method #{config.method}"
      return config

    service.loadContainer = (ctnOrigin) ->
      storage = @_containers
      # If ctnOrigin is undefined nothing to do
      unless ctnOrigin
        $log.warn "Undefined origin: I cannot load any container!"
        return 

      container = storage[ctnOrigin]
      
      # If container is not in local storage load it remotely and return the $http promise
      unless container
        $log.info "Ctn missing for #{ctnOrigin}. Try to load if from remote uri"
      
        deferred = $q.defer()
        $http( @prepareHttpRequest(ctnOrigin) )
        .success (ctn) ->
          storage[ctnOrigin] = ctn
          deferred.resolve ctn
        
        return deferred.promise
      
      $log.info "Ctn stored for #{ctnOrigin}. Nothing to load here!"
      # Otherwise returns the container itself wrapped in a promise-like obj
      # This trick allows wl-container to deal with this response with a single interface
      return {
        then: (callback) ->
          callback.call(@, container)
        }
    
    # loop containers and find container with type = containerType
    # find origins uri for that container
    # retrieve related data objs and return them
    service
])
# Generic container directive
.directive "wlContainer", [
  "DataRetrieverService"
  "$compile"
  "$log"
  (DataRetrieverService, $compile, $log) ->
    return (
      restrict: "E"
      scope:
        uri: "@"
        listening: "@"
        stack: "="
      controller: ($scope, $element, $attrs) ->
        ctrl = 
          notifier: (action,item) ->
            $log.debug "#{action}ing content #{item.id}!" 
            # TODO replace this after ContextManager refactoring
            $scope.$emit "notifyUserInteraction", action, item 
        ctrl
      
      link: (scope, element, attrs) ->

        compiled = false

        # Notify itself to the controller 
        observers = []
        if scope.listening
          observers = scope.listening.split(',')

        scope.$emit "containerAdded", scope.uri, observers

        # Observe chnages on stack property
        # When stack changes, contents has to be loaded / re-loaded
        # Notice: $watch is used with objectEquality enabled
        # This could have performance side effects on complex obj comparison
        # In this case we decided to use it becouse the stack object is simple enough
        # https://docs.angularjs.org/api/ng/type/$rootScope.Scope
        # The alternative - $watchCollection - has a bug about new/old value notification
        scope.$watch 'stack', (newStack, oldStack)->
          
          currentOrigin = newStack[scope.uri]
          
          if compiled and oldStack[scope.uri] is currentOrigin
             $log.debug "Nothing to do ctn #{scope.uri} indeed"
             return

          $log.debug "Updating container #{scope.uri} with content from #{currentOrigin}"    
          
          promise = DataRetrieverService.loadContainer currentOrigin
          promise.then (ctn) ->
            scope.container = ctn
            
            template = """
              <!-- Current container uri: #{currentOrigin} -->  
              <wl-#{scope.container.skin} items="container.items" notifier="notifier(action,item)"></wl-#{scope.container.skin}">
            """

            # TODO Try to find a smarter way to redraw the container
            element.html(template).show()
            $compile(element.contents()) scope
            compiled = true
        , true

    )
]





# Sample skin directive for news
angular.module("wordlift.ui.skins.famous", ["famous.angular", "ngRoute", "wordlift.containers.engine"])
.directive "wlNews", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope:
        items: "="
      template: """
        <fa-app style="height: 200px">
          <fa-surface fa-background-color="'red'">Hello world</fa-surface>
        </fa-app>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl

    )
]
# Sample skin directive for news
angular.module("wordlift.ui.skins.foundation", ["wordlift.containers.engine"])
.directive "wlTilesWithThumbsLoop", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope: 
        items: "="
      template: """
        <div class="row">
          <ul class="small-block-grid-2 large-block-grid-4">
            <li ng-repeat="item in items">
              <wl-thumb ng-mouseover="notifier('read', item)"></wl-thumb>
              <wl-tile></wl-tile>
            </li>
          </ul>
        </div>
      """
      

      link: (scope, element, attrs, ctrl) ->
        $log.debug ctrl
        scope.notifier = ctrl.notifier

    )
]
.directive "wlTile", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      scope: false
      template: """
        <wl-item-property name="title" emphasis="title"></wl-item-property>
        <wl-item-property name="content" emphasis="paragraph"></wl-item-property>
        <wl-link-to-item label="More info" emphasis="paragraph"></wl-link-to-item>
      """
    )
]

.directive "wlThumb", [
  "$log", 
  ($log) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        """
          <img ng-show="item.thumbnail" class="item-thumbnail" ng-src="{{item.thumbnail}}" />
        """
    )
]
.constant "emphasisLevels", {
  'title': 'h5'
  'paragraph': 'p'
}
.directive "wlItemProperty", [
  "$log", 
  "emphasisLevels",
  ($log, emphasisLevels) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        tag = emphasisLevels[tAttrs.emphasis]
        unless tag?
          tag = 'span'
        """
          <#{tag} ng-show="item.#{tAttrs.name}" class="item-#{tAttrs.name}">{{item.#{tAttrs.name}}}</#{tag}>
        """
    )
]
.directive "wlLinkToItem", [
  "$log", 
  "emphasisLevels",
  ($log, emphasisLevels) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        tag = emphasisLevels[tAttrs.emphasis]
        unless tag?
          tag = 'span'
        """
          <#{tag} ng-show="item.uri" class="item-uri"><a ng-href="{{item.uri}}">#{tAttrs.label}</a></#{tag}>
        """
    )
]

# Skin directive for Video
.directive "wlVideo", [
  "$sce"
  "$log"
  ($sce, $log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope:
        items: "="
      template: """
        <div ng-repeat="item in items">
            <h3>{{item.title}}</h3>
            <div class="flex-video">
               <iframe ng-src="{{trustSrc(item.meta.videoURL)}}" frameborder="0" allowfullscreen></iframe>
            </div>
        </div>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl
        scope.trustSrc = (src) ->
          $sce.trustAsResourceUrl(src)
    )
]