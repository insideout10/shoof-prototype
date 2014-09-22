(function() {
  var app,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  app = angular.module("shoof.ui", ["ngRoute", "famous.angular"]);

  app.controller("ShoofCtrl", [
    "ContextManagerService", "DataRetrieverService", "$scope", "$rootScope", "$log", function(ContextManagerService, DataRetrieverService, $scope, $rootScope, $log) {
      $scope.stack = {};
      $scope.observers = {};
      $scope.context = ContextManagerService.getContext();
      $rootScope.$on("contextChanged", function(event, property, value) {
        if (ContextManagerService.addProperty(property, value)) {
          return ContextManagerService.rewriteStack($scope.stack, $scope.observers);
        }
      });
      $rootScope.$on("containerAdded", function(event, ctnOrigin, ctnObserver) {
        $log.debug("Added ctn " + ctnOrigin + " reactive to " + ctnObserver);
        $scope.stack[ctnOrigin] = ctnOrigin;
        return $scope.observers[ctnOrigin] = ctnObserver;
      });
      $rootScope.$on("containerLoaded", function(event, ctnOrigin) {
        $log.debug("Notified about ctn " + ctnOrigin + " loading");
        $scope.stack[ctnOrigin] = ctnOrigin;
        return $scope.$digest();
      });
      $scope.dataFor = function(ctnOrigin) {
        return DataRetrieverService.retrieveOrLoadDataStructureFor(ctnOrigin);
      };
      $scope.submit = function() {
        $log.debug("submit");
        return $rootScope.$broadcast("contextChanged", $scope.contextProperty, $scope.contextPropertyValue);
      };
      return $scope.reset = function() {
        $log.debug("reset");
        ContextManagerService.resetContext();
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
        _allowedProperties: ['contentId', 'userId']
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
      service.toString = function(observers) {
        var chunks, property, _i, _len, _ref;
        chunks = [];
        _ref = this._allowedProperties;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          property = _ref[_i];
          if (this._context[property] && (__indexOf.call(observers, property) >= 0)) {
            chunks.push("" + property + "=" + this._context[property]);
          }
        }
        if (chunks.length > 0) {
          return "---" + (chunks.join('')) + ".json";
        } else {
          return ".json";
        }
      };
      service.rewriteOrigin = function(origin, observers) {
        return origin.replace(".json", this.toString(observers));
      };
      service.rewriteStack = function(stack, observers) {
        var id, origin;
        for (id in stack) {
          origin = stack[id];
          stack[id] = this.rewriteOrigin(id, observers[id]);
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
          $log.warn("Undefined origin within retrieveOrLoadDataStructureFor!");
          return;
        }
        container = this._containers[ctnOrigin];
        $log.debug(container);
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

  app.directive("wlContainer", [
    "$compile", "$log", function($compile, $log) {
      return {
        restrict: "E",
        scope: {
          uri: '@',
          stack: '=',
          observe: '@'
        },
        link: function(scope, element, attrs) {
          var observers, redraw;
          observers = [];
          if (scope.observe) {
            observers = scope.observe.split(',');
          }
          scope.$emit("containerAdded", scope.uri, observers);
          redraw = function(currentOrigin) {
            var template;
            $log.debug("Going to redraw ctn " + scope.uri);
            template = "<div class=\"row container-wrapper\">\n  <p class=\"debug-box\">Current container uri: <strong>" + currentOrigin + "</strong></p>  \n  <wl-" + scope.container.skin + " items=\"container.items\"></wl-" + scope.container.skin + "\">\n</div>";
            $log.debug(scope.container);
            element.html(template).show();
            $compile(element.contents())(scope);
            return true;
          };
          return scope.$watchCollection('stack', function(newStack, oldStack) {
            var currentOrigin;
            currentOrigin = newStack[scope.uri];
            $log.debug("Updating container " + scope.uri + " with content from " + currentOrigin);
            scope.container = scope.$parent.dataFor(currentOrigin);
            $log.debug(scope.container);
            if (!scope.container) {
              $log.warn("Content for ctn " + scope.uri + " is missing");
              return;
            }
            if (scope.container.success != null) {
              scope.container.success(function(ctn) {
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

  app.directive("wlNews", [
    "$log", function($log) {
      return {
        restrict: "E",
        scope: {
          items: "="
        },
        link: function(scope, element, attrs) {
          return scope.notify = function(item) {
            $log.debug("Clicked on video " + item.id);
            return scope.$emit("contextChanged", "contentId", item.id);
          };
        },
        template: "<ul class=\"small-block-grid-2 large-block-grid-2\">\n  <li ng-repeat=\"item in items\">\n    <img ng-src=\"{{item.meta.thumb}}\" ng-mouseover=\"notify(item)\" />\n    <h5>{{item.title}}</h5>\n    <p>\n    {{item.content}}<br />[ <a ng-href=\"{{item.content}}\">More Info</a> ]\n    </p>\n  </li>\n</ul>"
      };
    }
  ]);

  app.directive("wlVideo", [
    "$compile", "$injector", "$sce", "$log", function($compile, $injector, $sce, $log) {
      return {
        restrict: "E",
        scope: {
          items: "="
        },
        link: function(scope, element, attrs) {
          scope.trustSrc = function(src) {
            return $sce.trustAsResourceUrl(src);
          };
          return scope.notify = function(item) {
            $log.debug("Clicked on video " + item.id);
            return scope.$emit("contextChanged", "contentId", item.id);
          };
        },
        template: "<div ng-repeat=\"item in items\">\n    <h3>{{item.title}}</h3>\n    <div class=\"flex-video\">\n       <iframe ng-src=\"{{trustSrc(item.meta.videoURL)}}\" frameborder=\"0\" allowfullscreen></iframe>\n    </div>\n</div>"
      };
    }
  ]);

  console.log('ciao raga');

}).call(this);

//# sourceMappingURL=shoof-ui.js.map
