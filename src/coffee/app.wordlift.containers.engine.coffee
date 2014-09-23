
# Define the Wordlift Containers Engine
# Here is the core logic for containers rendering
# Skins are managed as separated modules
angular.module("wordlift.containers.engine", [])

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
  (ContextManagerService, DataRetrieverService, $scope, $rootScope, $log, storage) ->
    
    $scope.stack = {}    
    $scope.observers = {}    
    
    $scope.context = ContextManagerService.getContext()
    
    for uri, ctn of storage.containers
       $scope.stack[uri] = uri

    # Everytime the context changes the stack need to be update accordingly
    $rootScope.$on "contextChanged", (event, property, value) ->
      if ContextManagerService.addProperty property, value
        ContextManagerService.rewriteStack($scope.stack, $scope.observers)
    
    $rootScope.$on "containerAdded", (event, ctnOrigin, ctnObserver) ->
      $log.debug "Added ctn #{ctnOrigin} reactive to #{ctnObserver}"
      $scope.stack[ctnOrigin] = ctnOrigin
      $scope.observers[ctnOrigin] = ctnObserver

    # Test fn: TO BE REMOVED
    $scope.submit = () ->
      $log.debug "submit"
      $rootScope.$broadcast "contextChanged", $scope.contextProperty, $scope.contextPropertyValue 
     # Test fn TO BE REMOVED
    $scope.reset = () ->
      $log.debug "reset"
      ContextManagerService.resetContext()
      ContextManagerService.resetStack $scope.stack
      $scope.contextProperty = undefined
      $scope.contextPropertyValue = undefined

])
# Represents and manage the Context
# The context is made up a set of key / value properties
# @_allowedProperties define which properties are allowed within the context definition
# The current context can be outputed as a querystring fragment
# Append this fragment to an existing uri means 
# to apply a context to an existing container, genereting a new container reference 
.service("ContextManagerService", [
  "$log", 
  ($log) ->
  
    service =
      _context: {}
      # Just a fake property
      _allowedProperties: ['contentId', 'userId']
    
    # Returns the current context
    service.getContext = ->
      @_context
    # Add a property to the current context, just if the parameter is allowed to be used  
    service.addProperty = (property, value)->
      unless property in @_allowedProperties
        $log.warn "ContextManager does not allow property #{property}"
        return false 

      @_context[property] = value
      true
    # Returns the context as querystring fragment
    # This output can be appended to containers origins, 
    # meaning that the current context is applied to current containers
    # Note: this implementazione is just for test pourpose
    service.toString = (observers)->
      chunks = []
      for property in @_allowedProperties
        if @_context[property] and (property in observers)
          chunks.push "#{property}=#{@_context[property]}"
      if chunks.length > 0
        return "---#{chunks.join('')}.json"
      else
        return ".json"
        
    # Rewrite origin means append the context to the origin
    # The oupput is a new container reference
    service.rewriteOrigin = (origin, observers)->
      origin.replace ".json", @toString(observers)
    # Rewrite the whale page stack
    service.rewriteStack = (stack, observers)->
      for id, origin of stack    
        stack[id] = @rewriteOrigin id, observers[id]
      stack
    # Reset the page stack
    service.resetStack = (stack)->
      for id, origin of stack  
        stack[id] = id
      stack
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
        $http
          method: 'GET' 
          url: ctnOrigin
          responseType: 'json'
        .success (ctn) ->
          storage[ctnOrigin] = ctn
          deferred.resolve ctn
        
        return deferred.promise
      
      $log.info "Ctn stored for #{ctnOrigin}. Nothing to load here!"
      $log.debug container
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
        observe: "@"
        stack: "="
      controller: ($scope, $element, $attrs) ->
        ctrl = 
          notifier: (action,item) ->
            $log.debug "#{action}ing content #{item.id}!" 
            # TODO replace this after ContextManager refactoring
            $scope.$emit "contextChanged", "contentId", item.id 
        ctrl
      link: (scope, element, attrs) ->

        compiled = false

        # Notify itself to the controller 
        observers = []
        if scope.observe
          observers = scope.observe.split(',')

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
            <div class="row container-wrapper">
              <p class="debug-box">Current container uri: <strong>#{currentOrigin}</strong></p>  
              <wl-#{scope.container.skin} items="container.items"></wl-#{scope.container.skin}">
            </div>"""

            # TODO Try to find a smarter way to redraw the container
            element.html(template).show()
            $compile(element.contents()) scope
            compiled = true
        , true

    )
]



