(function() {
  var app, injector;

  app = angular.module("shoof.ui", []);

  app.controller("UiCtrl", ["ContextService", "$scope", function(ContextService, $scope) {}]);

  app.service("ContextService", [
    function() {
      var service;
      service = {};
      service.foo = function() {
        console.log("I am the context");
      };
      return service;
    }
  ]);

  app.service("TopNewsDataBinder", [
    "$window", function($window) {
      var containers, origins, service;
      containers = $window.reply.containers;
      origins = $window.reply.origins;
      service = {};
      service.load = function(containerType) {};
      return service;
    }
  ]);

  app.service("DefaultDataAdapter", [
    function() {
      var service;
      service = {};
      service.adapt = function(items) {
        return data;
      };
      return service;
    }
  ]);

  app.directive("wlContainer", [
    "$compile", "$injector", function($compile, $injector) {
      return {
        restrict: "E",
        scope: {
          type: "=",
          dataBinder: "=",
          dataAdapter: "=",
          dataRenderer: "="
        },
        link: function(scope, element, attrs) {
          var adapter, binder, template;
          binder = $injector.get(scope.dataBinder);
          adapter = $injector.get(scope.dataAdapter);
          scope.items = binder.loadData(scope.type);
          adapter.adapt(items);
          template = "<div><div ng-repeat=\"item in items\"><wl-" + scope.renderer + " item=\"item\"></wl-" + scope.renderer + "></div></div>";
          element.html(template).show();
          $compile(element.contents())(scope);
        }
      };
    }
  ]);

  app.directive("wlNewsRenderer", [
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

  injector = angular.bootstrap(document, ["shoof.ui"]);

}).call(this);

//# sourceMappingURL=shoof-ui.js.map
