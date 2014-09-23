(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  angular.module("wordlift.containers.engine", []).provider("storage", function() {
    var containers;
    containers = void 0;
    return {
      setContainers: function(cnts) {
        return containers = cnts;
      },
      $get: function() {
        return {
          containers: containers
        };
      }
    };
  }).config(function(storageProvider) {
    return storageProvider.setContainers(window.containers);
  }).controller("wlContainersEngineCtrl", [
    "ContextManagerService", "DataRetrieverService", "$scope", "$rootScope", "$log", "storage", function(ContextManagerService, DataRetrieverService, $scope, $rootScope, $log, storage) {
      var ctn, uri, _ref;
      $scope.stack = {};
      $scope.observers = {};
      $scope.context = ContextManagerService.getContext();
      _ref = storage.containers;
      for (uri in _ref) {
        ctn = _ref[uri];
        $scope.stack[uri] = uri;
      }
      $scope.resetStack = function() {
        var id, origin, _ref1, _results;
        _ref1 = $scope.stack;
        _results = [];
        for (id in _ref1) {
          origin = _ref1[id];
          _results.push($scope.stack[id] = id);
        }
        return _results;
      };
      $rootScope.$on("notifyUserInteraction", function(event, action, item) {
        var id, newOrigin, origin, _ref1, _results;
        ContextManagerService.trackUserInteraction(action, item);
        $log.info("Context updated! Let's update the page stack accordingly!");
        _ref1 = $scope.stack;
        _results = [];
        for (id in _ref1) {
          origin = _ref1[id];
          newOrigin = ContextManagerService.rewriteOrigin(id, $scope.observers[id]);
          $log.debug("From " + id + " to " + newOrigin);
          _results.push($scope.stack[id] = newOrigin);
        }
        return _results;
      });
      $rootScope.$on("containerAdded", function(event, ctnOrigin, ctnObserver) {
        $log.debug("Added ctn " + ctnOrigin + " reactive to " + ctnObserver);
        $scope.stack[ctnOrigin] = ctnOrigin;
        return $scope.observers[ctnOrigin] = ctnObserver;
      });
      $scope.submit = function() {
        $log.debug("submit");
        return $rootScope.$broadcast("contextChanged", $scope.contextProperty, $scope.contextPropertyValue);
      };
      return $scope.reset = function() {
        $log.debug("reset");
        ContextManagerService.resetContext();
        $scope.resetStack();
        $scope.contextProperty = void 0;
        return $scope.contextPropertyValue = void 0;
      };
    }
  ]).service("ContextManagerService", [
    "$log", "$window", function($log, $window) {
      var service;
      service = {
        _context: {
          userProperties: [],
          userInteractions: [],
          lastInteractionItemId: function() {
            var interaction;
            interaction = this.userInteractions.slice(0).pop();
            return interaction.item.id;
          }
        }
      };
      service.getContext = function() {
        return this._context;
      };
      service.trackUserInteraction = function(a, i) {
        this._context.userInteractions.push({
          action: a,
          item: i
        });
        $log.debug("Goingo to notify userInteraction to analytics!");
        if (typeof $window.ga === "function") {
          $window.ga("send", "event", "userInteraction", action, item.id);
        }
        return true;
      };
      service.rewriteOrigin = function(origin, observers) {
        var chunks, newUrl;
        newUrl = "";
        chunks = [];
        if (__indexOf.call(observers, "contentId") >= 0) {
          chunks.push("contentId=" + (this._context.lastInteractionItemId()));
        }
        if (chunks.length > 0) {
          newUrl = "---" + (chunks.join('')) + ".json";
        } else {
          newUrl = ".json";
        }
        return origin.replace(".json", newUrl);
      };
      service.resetContext = function() {
        return this._context = {};
      };
      return service;
    }
  ]).service("DataRetrieverService", [
    "$http", "$log", "$rootScope", "$q", "storage", function($http, $log, $rootScope, $q, storage) {
      var service;
      service = {
        _containers: storage.containers
      };
      service.loadContainer = function(ctnOrigin) {
        var container, deferred;
        storage = this._containers;
        if (!ctnOrigin) {
          $log.warn("Undefined origin: I cannot load any container!");
          return;
        }
        container = storage[ctnOrigin];
        if (!container) {
          $log.info("Ctn missing for " + ctnOrigin + ". Try to load if from remote uri");
          deferred = $q.defer();
          $http({
            method: 'GET',
            url: ctnOrigin,
            responseType: 'json'
          }).success(function(ctn) {
            storage[ctnOrigin] = ctn;
            return deferred.resolve(ctn);
          });
          return deferred.promise;
        }
        $log.info("Ctn stored for " + ctnOrigin + ". Nothing to load here!");
        return {
          then: function(callback) {
            return callback.call(this, container);
          }
        };
      };
      return service;
    }
  ]).directive("wlContainer", [
    "DataRetrieverService", "$compile", "$log", function(DataRetrieverService, $compile, $log) {
      return {
        restrict: "E",
        scope: {
          uri: "@",
          observe: "@",
          stack: "="
        },
        controller: function($scope, $element, $attrs) {
          var ctrl;
          ctrl = {
            notifier: function(action, item) {
              $log.debug("" + action + "ing content " + item.id + "!");
              return $scope.$emit("notifyUserInteraction", action, item);
            }
          };
          return ctrl;
        },
        link: function(scope, element, attrs) {
          var compiled, observers;
          compiled = false;
          observers = [];
          if (scope.observe) {
            observers = scope.observe.split(',');
          }
          scope.$emit("containerAdded", scope.uri, observers);
          return scope.$watch('stack', function(newStack, oldStack) {
            var currentOrigin, promise;
            currentOrigin = newStack[scope.uri];
            if (compiled && oldStack[scope.uri] === currentOrigin) {
              $log.debug("Nothing to do ctn " + scope.uri + " indeed");
              return;
            }
            $log.debug("Updating container " + scope.uri + " with content from " + currentOrigin);
            promise = DataRetrieverService.loadContainer(currentOrigin);
            return promise.then(function(ctn) {
              var template;
              scope.container = ctn;
              template = "<div class=\"row container-wrapper\">\n  <p class=\"debug-box\">Current container uri: <strong>" + currentOrigin + "</strong></p>  \n  <wl-" + scope.container.skin + " items=\"container.items\"></wl-" + scope.container.skin + "\">\n</div>";
              element.html(template).show();
              $compile(element.contents())(scope);
              return compiled = true;
            });
          }, true);
        }
      };
    }
  ]);

  angular.module("wordlift.ui.skins.famous", ["famous.angular", "ngRoute", "wordlift.containers.engine"]).directive("wlNews", [
    "$log", function($log) {
      return {
        restrict: "E",
        require: "^wlContainer",
        scope: {
          items: "="
        },
        template: "<fa-app style=\"height: 200px\">\n  <fa-surface fa-background-color=\"'red'\">Hello world</fa-surface>\n</fa-app>",
        link: function(scope, element, attrs, ctrl) {
          return scope.container = ctrl;
        }
      };
    }
  ]);

  angular.module("wordlift.ui.skins.foundation", ["wordlift.containers.engine"]).directive("wlNews", [
    "$log", function($log) {
      return {
        restrict: "E",
        require: "^wlContainer",
        scope: {
          items: "="
        },
        template: "<ul class=\"small-block-grid-2 large-block-grid-2\">\n  <li ng-repeat=\"item in items\">\n    <img ng-src=\"{{item.meta.thumb}}\" ng-mouseover=\"container.notifier('read', item)\" />\n    <h5>{{item.title}}</h5>\n    <p>\n    {{item.content}}<br />[ <a ng-href=\"{{item.content}}\">More Info</a> ]\n    </p>\n  </li>\n</ul>",
        link: function(scope, element, attrs, ctrl) {
          return scope.container = ctrl;
        }
      };
    }
  ]).directive("wlVideo", [
    "$sce", "$log", function($sce, $log) {
      return {
        restrict: "E",
        require: "^wlContainer",
        scope: {
          items: "="
        },
        template: "<div ng-repeat=\"item in items\">\n    <h3>{{item.title}}</h3>\n    <div class=\"flex-video\">\n       <iframe ng-src=\"{{trustSrc(item.meta.videoURL)}}\" frameborder=\"0\" allowfullscreen></iframe>\n    </div>\n</div>",
        link: function(scope, element, attrs, ctrl) {
          scope.container = ctrl;
          return scope.trustSrc = function(src) {
            return $sce.trustAsResourceUrl(src);
          };
        }
      };
    }
  ]);

}).call(this);

//# sourceMappingURL=wordlift-containers.js.map
