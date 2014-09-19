(function() {
  var app;

  app = angular.module("shoof.ui", []);

  app.controller("ShoofCtrl", [
    "ContextManagerService", "DataRetrieverService", "$scope", "$log", function(ContextManagerService, DataRetrieverService, $scope, $log) {
      return $scope.dataFor = function(containerOrigin) {
        return DataRetrieverService.retrieveOrLoadDataStructureFor(ctn);
      };
    }
  ]);

  app.service("ContextManagerService", [
    function() {
      var service;
      service = {};
      service.foo = function() {
        console.log("I am the context");
      };
      return service;
    }
  ]);

  app.service("DataRetrieverService", [
    "$log", function($log) {
      var service, _containers;
      service = _containers = {};
      service.setInPageContainers = function(containers) {
        $log.debug("Going to set containers " + containers);
        return this._containers = containers;
      };
      service.retrieveOrLoadDataStructureFor = function(containerOrigin) {
        return this._containers[containerOrigin];
      };
      return service;
    }
  ]);

  app.directive("wlNews", [
    "$compile", "$injector", function($compile, $injector) {
      return {
        restrict: "E",
        scope: {
          item: "="
        },
        template: "<div>{{item.title}}</div>"
      };
    }
  ]);

  app.directive("wlContainer", [
    "DataRetrieverService", "$compile", "$log", function(DataRetrieverService, $compile, $log) {
      return {
        restrict: "E",
        scope: {
          ctn: '@',
          uri: '@'
        },
        link: function(scope, element, attrs) {
          var template;
          scope.container = DataRetrieverService.retrieveOrLoadDataStructureFor(scope.uri);
          scope.notify = function() {
            return $log.debug("Click on element");
          };
          template = "<div class=\"row\">\n<p>Current container uri <small>{{container.origin}}</small></p>  \n<div ng-repeat=\"item in container.items\">\n  <wl-" + container.skin + " item=\"item\" ng-click=\"notify()\"></wl-" + container.skin + "\">\n</div>\n</div>";
          element.html(template).show();
          $compile(element.contents())(scope);
        }
      };
    }
  ]);

  window.containers = {};

  $(document).ready(function() {
    var injector;
    injector = angular.bootstrap(document, ["shoof.ui"]);
    return injector.invoke([
      'EditorService', function(EditorService) {
        return DataRetrieverService.setInPageContainers(window.containers);
      }
    ]);
  });

}).call(this);

//# sourceMappingURL=shoof-ui.js.map
