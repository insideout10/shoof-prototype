# Test mock prototype
app = angular.module("shoof.ui", [])

# UiCtrl manage communications between skins, context and data retriever
app.controller "ShoofCtrl", [
  "ContextManagerService"
  "DataRetrieverService"
  "$scope"
  "$rootScope"
  "$log"
  (ContextManagerService, DataRetrieverService, $scope, $rootScope, $log) ->
    
    $scope.stack = {}    
    $scope.context = ContextManagerService.getContext()
    
    # Everytime the context changes the stack need to be update accordingly
    $rootScope.$on "contextChanged", (event, property, value) ->
      if ContextManagerService.addProperty property, value
        ContextManagerService.rewriteStack($scope.stack)
    
    # Once in page containers are properly loaded
    # the controller it's notified and stack is updated
    $rootScope.$on "containerLoaded", (event, ctnOrigin) ->
      $log.debug "Notified about ctn #{ctnOrigin} loading"
      $scope.stack[ctnOrigin] = ctnOrigin
      # TODO Investigate about: it seems to berequired an explicit $digist() execution here 
      $scope.$digest()

    # Retrieve container data trough a container uri / origin
    # Data retrieving is delegated to DataRetrieverService
    $scope.dataFor = (ctnOrigin) ->
      DataRetrieverService.retrieveOrLoadDataStructureFor(ctnOrigin)


    # Test fn
    $scope.submit = () ->
      $log.debug "submit"
      $rootScope.$broadcast "contextChanged", $scope.contextProperty, $scope.contextPropertyValue 
     # Test fn
    $scope.reset = () ->
      $log.debug "reset"
      ContextManagerService.resetContext
      ContextManagerService.resetStack $scope.stack
      $scope.contextProperty = undefined
      $scope.contextPropertyValue = undefined

]

# Represents and manage the Context
# The context is made up a set of key / value properties
# @_allowedProperties define which properties are allowed within the context definition
# The current context can be outputed as a querystring fragment
# Append this fragment to an existing uri means 
# to apply a context to an existing container, genereting a new container reference 
app.service "ContextManagerService", [
  "$log", 
  ($log) ->
  
    service =
      _context: {}
      # Just a fake property
      _allowedProperties: ['foo']
    
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
    service.toString = ()->
      out = "---"
      for property in @_allowedProperties
        out += "#{property}=#{@_context[property]}"
    
      out+= ".json"
      out
    # Rewrite origin means append the context to the origin
    # The oupput is a new container reference
    service.rewriteOrigin = (origin)->
      origin.replace ".json", @toString()
    # Rewrite the whale page stack
    service.rewriteStack = (stack)->
      for id, origin of stack  
        stack[id] = @rewriteOrigin id
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
]

# Data retrieving specilized service
# Store containers content in @_containers
# If a data structure is missing try to load from remote
app.service "DataRetrieverService", [
  "$http",
  "$log",
  "$rootScope",
  ($http, $log, $rootScope) ->
    
    service = 
      _containers: {} 
    
    service.setInPageContainers = (containers) ->
      @_containers = containers
      # Loops on containers and notify them to the controller
      for origin of @_containers
        $log.debug "Going to notify ctn #{origin} was loaded!"
        $rootScope.$broadcast "containerLoaded", origin

    # retrieve data for a container with uri ctnOrigin
    # if it's presente in containers local storage @_containers return it
    # Otherwise try to retrieve by $http
    service.retrieveOrLoadDataStructureFor = (ctnOrigin) ->
      # If ctnOrigin is undefined nothing to do
      unless ctnOrigin
        return 

      container = @_containers[ctnOrigin]
      
      # If container is not in local storage load it remotely and return the $http promise
      unless container
        $log.warn "Ctn #{ctnOrigin} missing: try to load it remotely"
              
        promise = $http.get ctnOrigin
        return promise
      # Otherwise returns the container itself
      container
    
    # loop containers and find container with type = containerType
    # find origins uri for that container
    # retrieve related data objs and return them
    service
]

# Generic container directive
app.directive "wlContainer", [
  "$compile"
  "$log"
  ($compile, $log) ->
    return (
      restrict: "E"
      scope:
        uri: '@'
        stack: '='
      link: (scope, element, attrs) ->

        # Private function used to redraw the directive content
        redraw = (currentOrigin)->
          $log.debug "Going to redraw ctn #{scope.uri}"
          template = """
            <div class="row container-wrapper">
              <p class="debug-box">Current container uri: <strong>#{currentOrigin}</strong></p>  
              <wl-#{scope.container.skin} items="container.items"></wl-#{scope.container.skin}">
            </div>"""
          $log.debug template
          element.html(template).show()
          $compile(element.contents()) scope
          true

        # Observe chnages on stack property
        # If stack changes, contents need to be retrieved
        # If DataRetriever return a promise, the promise is executed
        # If the promise fails redrawing is aborted
        scope.$watchCollection 'stack', (newStack, oldStack)->
          
          $log.debug 'New value for page stack...'    
          $log.debug oldStack[scope.uri]
          $log.debug newStack[scope.uri]
          
          # if newStack[scope.uri] is oldStack[scope.uri]
          #   $log.debug "Nothing to do indeed"
          #   return
          currentOrigin = newStack[scope.uri]
          # TODO $parent scope usage should be avoided
          scope.container = scope.$parent.dataFor(currentOrigin)
          
          unless scope.container
            $log.warn "Content for ctn #{scope.uri} is missing"
            return 

          if scope.container.success?
            scope.container.success (ctn) ->
              $log.debug angular.fromJson(ctn)
              # set the scope container equal to ctn response
              scope.container = ctn
              redraw(currentOrigin)
            scope.container.error (response) ->
              $log.warn "There was an issue trying to load ctn #{currentOrigin}. I restore the container"
              scope.container = scope.$parent.dataFor(scope.uri)
              redraw(scope.uri)  
          else
            redraw(currentOrigin) 
           

        scope.notify = ()->
          $log.debug "Click on element"

    )
]

# Define window.containers: it's the storage for in-page loaded containers
window.containers = {}
# Once the page is loaded, angula app is bootstraped
$( document ).ready ()->
  injector = angular.bootstrap(document, ["shoof.ui"])
  injector.invoke(['DataRetrieverService', (DataRetrieverService) ->
    DataRetrieverService.setInPageContainers window.containers
  ])



# Sample skin directive for news
app.directive "wlNews", [
  "$compile"
  "$injector"
  ($compile, $injector) ->
    return (
      restrict: "E"
      scope:
        items: "="
      template: """
        <ul ng-repeat="item in items">
          <li>
            <div>{{item.title}}</div>
          </li>
        </ul>
      """
    )
]

# Skin directive for Video
app.directive "wlVideo", [
  "$compile"
  "$injector"
  "$sce"
  ($compile, $injector, $sce) ->
    return (
      restrict: "E"
      scope:
        items: "="
      link: (scope, element, attrs) ->
        scope.trustSrc = (src) ->
          $sce.trustAsResourceUrl(src)
      template: """
        <ul ng-repeat="item in items">
          <li>
            <div>{{item.title}}</div>
            <div class="flex-video">
               <iframe width="300" height="250" ng-src="{{trustSrc(item.meta.videoURL)}}" frameborder="0" allowfullscreen></iframe>
            </div>
          </li>
        </ul>
      """
    )
]