(function() {
  var app,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  app = angular.module("shoof.ui", []);

  app.controller("ShoofCtrl", [
    "ContextManagerService", "DataRetrieverService", "$scope", "$rootScope", "$log", function(ContextManagerService, DataRetrieverService, $scope, $rootScope, $log) {
      var contextChanged;
      $scope.stack = {};
      $scope.context = ContextManagerService.getContext();
      contextChanged = function(property, value) {};
      $rootScope.$on("contextChanged", function(event, property, value) {
        if (ContextManagerService.addProperty(property, value)) {
          return ContextManagerService.rewriteStack($scope.stack);
        }
      });
      $rootScope.$on("containerLoaded", function(event, ctnOrigin) {
        $log.debug("Notified about ctn " + ctnOrigin + " loading");
        $scope.stack[ctnOrigin] = ctnOrigin;
        return $scope.$digest();
      });
      $scope.dataFor = function(ctnOrigin) {
        return DataRetrieverService.retrieveOrLoadDataStructureFor(ctnOrigin);
      };
      $scope.test = function() {
        $log.debug("Rewriting ctn uri");
        return $scope.stack["/data/News1.json"] = "/data/News1---foo=a.json";
      };
      $scope.submit = function() {
        $log.debug("submit");
        return $rootScope.$broadcast("contextChanged", $scope.contextProperty, $scope.contextPropertyValue);
      };
      return $scope.reset = function() {
        $log.debug("reset");
        ContextManagerService.resetContext;
        ContextManagerService.resetStack($scope.stack);
        $scope.contextProperty = void 0;
        return $scope.contextPropertyValue = void 0;
      };
    }
  ]);

  app.service("ContextManagerService", [
    "$log", function($log) {
      var service;
      service = {
        _context: {},
        _allowedProperties: ['foo']
      };
      service.getContext = function() {
        return this._context;
      };
      service.addProperty = function(property, value) {
        if (__indexOf.call(this._allowedProperties, property) < 0) {
          $log.warn("ContextManager does not allow property " + property);
          return false;
        }
        this._context[property] = value;
        return true;
      };
      service.toString = function() {
        var out, property, _i, _len, _ref;
        out = "---";
        _ref = this._allowedProperties;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          property = _ref[_i];
          out += "" + property + "=" + this._context[property];
        }
        out += ".json";
        return out;
      };
      service.rewriteOrigin = function(origin) {
        return origin.replace(".json", this.toString());
      };
      service.rewriteStack = function(stack) {
        var id, origin;
        for (id in stack) {
          origin = stack[id];
          stack[id] = this.rewriteOrigin(id);
        }
        return stack;
      };
      service.resetStack = function(stack) {
        var id, origin;
        for (id in stack) {
          origin = stack[id];
          stack[id] = id;
        }
        return stack;
      };
      service.resetContext = function() {
        return this._context = {};
      };
      return service;
    }
  ]);

  app.service("DataRetrieverService", [
    "$http", "$log", "$rootScope", function($http, $log, $rootScope) {
      var service;
      service = {
        _containers: {}
      };
      service.setInPageContainers = function(containers) {
        var origin, _results;
        this._containers = containers;
        _results = [];
        for (origin in this._containers) {
          $log.debug("Going to notify ctn " + origin + " was loaded!");
          _results.push($rootScope.$broadcast("containerLoaded", origin));
        }
        return _results;
      };
      service.retrieveOrLoadDataStructureFor = function(ctnOrigin) {
        var container, promise;
        if (!ctnOrigin) {
          return;
        }
        container = this._containers[ctnOrigin];
        if (!container) {
          $log.warn("Ctn " + ctnOrigin + " missing: try to load it remotely");
          promise = $http.get(ctnOrigin);
          return promise;
        }
        return container;
      };
      return service;
    }
  ]);

  app.directive("wlNews", [
    "$compile", "$injector", function($compile, $injector) {
      return {
        restrict: "E",
        scope: {
          items: "="
        },
        template: "<ul ng-repeat=\"item in items\">\n  <li>\n    <div>{{item.title}}</div>\n  </li>\n</ul>"
      };
    }
  ]);

  app.directive("wlContainer", [
    "$compile", "$log", function($compile, $log) {
      return {
        restrict: "E",
        scope: {
          uri: '@',
          stack: '='
        },
        link: function(scope, element, attrs) {
          var redraw;
          redraw = function(currentOrigin) {
            var template;
            $log.debug("Going to redraw ctn " + scope.uri);
            template = "<div class=\"row\">\n  <p>Current container uri <small>" + currentOrigin + "</small></p>  \n  <wl-" + scope.container.skin + " items=\"container.items\"></wl-" + scope.container.skin + "\">\n</div>";
            $log.debug(template);
            element.html(template).show();
            $compile(element.contents())(scope);
            return true;
          };
          scope.$watchCollection('stack', function(newStack, oldStack) {
            var currentOrigin;
            $log.debug('New value for page stack...');
            $log.debug(oldStack[scope.uri]);
            $log.debug(newStack[scope.uri]);
            currentOrigin = newStack[scope.uri];
            scope.container = scope.$parent.dataFor(currentOrigin);
            if (!scope.container) {
              $log.warn("Content for ctn " + scope.uri + " is missing");
              return;
            }
            if (scope.container.success != null) {
              scope.container.success(function(ctn) {
                $log.debug(angular.fromJson(ctn));
                scope.container = ctn;
                return redraw(currentOrigin);
              });
              return scope.container.error(function(response) {
                $log.warn("There was an issue trying to load ctn " + currentOrigin + ". I restore the container");
                scope.container = scope.$parent.dataFor(scope.uri);
                return redraw(scope.uri);
              });
            } else {
              return redraw(currentOrigin);
            }
          });
          return scope.notify = function() {
            return $log.debug("Click on element");
          };
        }
      };
    }
  ]);

  window.containers = {};

  $(document).ready(function() {
    var injector;
    injector = angular.bootstrap(document, ["shoof.ui"]);
    return injector.invoke([
      'DataRetrieverService', function(DataRetrieverService) {
        return DataRetrieverService.setInPageContainers(window.containers);
      }
    ]);
  });

}).call(this);

//# sourceMappingURL=shoof-ui.js.map
