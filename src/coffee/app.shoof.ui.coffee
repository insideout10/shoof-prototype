# Test mock prototype
app = angular.module("shoof.ui", [])

# UiCtrl manage communications between renderers and services
app.controller "ShoofCtrl", [
  "ContextManagerService"
  "DataRetrieverService"
  "$scope"
  "$rootScope"
  "$log"
  (ContextManagerService, DataRetrieverService, $scope, $rootScope, $log) ->
    
    $scope.stack = {}    
    $scope.context = ContextManagerService.getContext()

    contextChanged = (property, value) ->
        
    $rootScope.$on "contextChanged", (event, property, value) ->
      if ContextManagerService.addProperty property, value
        ContextManagerService.rewriteStack($scope.stack)
        
    $rootScope.$on "containerLoaded", (event, ctnOrigin) ->
      $log.debug "Notified about ctn #{ctnOrigin} loading"
      $scope.stack[ctnOrigin] = ctnOrigin
      # TODO investigate 
      $scope.$digest()

    # Retrieve container data trough a container uri / origin
    $scope.dataFor = (ctnOrigin) ->
      DataRetrieverService.retrieveOrLoadDataStructureFor(ctnOrigin)

    # Test fn
    $scope.test = () ->
      $log.debug "Rewriting ctn uri"
      $scope.stack["/data/News1.json"] = "/data/News1---foo=a.json"

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

# Represents the Context
app.service "ContextManagerService", [
  "$log", 
  ($log) ->
  
    service =
      _context: {}
      # Just a fake property
      _allowedProperties: ['foo']
      
    service.getContext = ->
      @_context
    service.addProperty = (property, value)->
      unless property in @_allowedProperties
        $log.warn "ContextManager does not allow property #{property}"
        return false 

      @_context[property] = value
      true
    service.toString = ()->
      out = "---"
      for property in @_allowedProperties
        out += "#{property}=#{@_context[property]}"
    
      out+= ".json"
      out
    service.rewriteOrigin = (origin)->
      origin.replace ".json", @toString()
    service.rewriteStack = (stack)->
      for id, origin of stack  
        stack[id] = @rewriteOrigin id
      stack
    service.resetStack = (stack)->
      for id, origin of stack  
        stack[id] = id
      stack
    
    service.resetContext = ()->
      @_context = {}

    service
]

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

    service.retrieveOrLoadDataStructureFor = (ctnOrigin) ->
      unless ctnOrigin
        return 

      container = @_containers[ctnOrigin]
      
      unless container
        $log.warn "Ctn #{ctnOrigin} missing: try to load it remotely"
              
        promise = $http.get ctnOrigin
        return promise

      container
    
    # loop containers and find container with type = containerType
    # find origins uri for that container
    # retrieve related data objs and return them
    service
]

# Generic container directive
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

        redraw = (currentOrigin)->
          $log.debug "Going to redraw ctn #{scope.uri}"
          template = """
            <div class="row">
              <p>Current container uri <small>#{currentOrigin}</small></p>  
              <wl-#{scope.container.skin} items="container.items"></wl-#{scope.container.skin}">
            </div>"""

          $log.debug template
          
          element.html(template).show()
          $compile(element.contents()) scope
          true

        # Observe stack chnages
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

window.containers = {}

$( document ).ready ()->
  injector = angular.bootstrap(document, ["shoof.ui"])
  injector.invoke(['DataRetrieverService', (DataRetrieverService) ->
    DataRetrieverService.setInPageContainers window.containers
  ])


