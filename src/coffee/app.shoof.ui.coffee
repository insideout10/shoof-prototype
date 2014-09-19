# Test mock prototype
app = angular.module("shoof.ui", [])

# UiCtrl manage communications between renderers and services
app.controller "ShoofCtrl", [
  "ContextManagerService"
  "DataRetrieverService"
  "$scope"
  "$log"
  (ContextManagerService, DataRetrieverService, $scope, $log) ->
    $scope.dataFor = (containerOrigin) ->
      DataRetrieverService.retrieveOrLoadDataStructureFor(ctn)
]

# Represents the Context
app.service "ContextManagerService", [->
  service = {}
  service.foo = ->
    console.log "I am the context"
    return

  service
]
app.service "DataRetrieverService", [
  "$log"
  ($log) ->
    
    service = 
      _containers: {} 
    service.setInPageContainers = (containers) ->
      $log.debug "Going to set containers #{containers}"
      @_containers = containers

    service.retrieveOrLoadDataStructureFor = (containerOrigin) ->
      @_containers[containerOrigin]
    
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
        item: "="
      template: "<div>{{item.title}}</div>"
    )
]

# Generic container directive
app.directive "wlContainer", [
  "DataRetrieverService"
  "$compile"
  "$log"
  (DataRetrieverService, $compile, $log) ->
    return (
      restrict: "E"
      scope:
        ctn: '@'
        uri: '@'

      link: (scope, element, attrs) ->
        # Load container
        scope.container = DataRetrieverService.retrieveOrLoadDataStructureFor(scope.uri)
        $log.debug scope.uri
        scope.notify = ()->
          $log.debug "Click on element"
        
        template = """
          <div class="row">
          <p>Current container uri <small>{{container.origin}}</small></p>  
          <div ng-repeat="item in container.items">
            <wl-#{container.skin} item="item" ng-click="notify()"></wl-#{container.skin}">
          </div>
          </div>"""

        element.html(template).show()
        $compile(element.contents()) scope
        return
    )
]

window.containers = {}

$( document ).ready ()->
  injector = angular.bootstrap(document, ["shoof.ui"])
  injector.invoke(['EditorService', (EditorService) ->
    DataRetrieverService.setInPageContainers window.containers
  ])


