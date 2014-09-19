# Test mock prototype
app = angular.module("shoof.ui", [])

# UiCtrl manage communications between renderers and services
app.controller "UiCtrl", [
  "ContextService"
  "$scope"
  (ContextService, $scope) ->
]

# Represents the Context
app.service "ContextService", [->
  service = {}
  service.foo = ->
    console.log "I am the context"
    return

  service
]
app.service "TopNewsDataBinder", [
  "$window"
  ($window) ->
    containers = $window.reply.containers
    origins = $window.reply.origins
    service = {}
    service.load = (containerType) ->

    
    # loop containers and find container with type = containerType
    # find origins uri for that container
    # retrieve related data objs and return them
    return service
]
app.service "DefaultDataAdapter", [->
  service = {}
  service.adapt = (items) ->
    
    # loops data
    # Apply data manipulation if nedeed
    data

  service
]

# Generic container directive
app.directive "wlContainer", [
  "$compile"
  "$injector"
  ($compile, $injector) ->
    return (
      restrict: "E"
      scope:
        type: "="
        dataBinder: "="
        dataAdapter: "="
        dataRenderer: "="

      link: (scope, element, attrs) ->
        binder = $injector.get(scope.dataBinder)
        adapter = $injector.get(scope.dataAdapter)
        scope.items = binder.loadData(scope.type)
        adapter.adapt items
        template = "<div><div ng-repeat=\"item in items\"><wl-" + scope.renderer + " item=\"item\"></wl-" + scope.renderer + "></div></div>"
        element.html(template).show()
        $compile(element.contents()) scope
        return
    )
]

# Generic container directive
app.directive "wlNewsRenderer", [
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
injector = angular.bootstrap(document, ["shoof.ui"])