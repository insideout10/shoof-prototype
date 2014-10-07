(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  angular.module("wordlift.containers.engine", ["geolocation"]).provider("storage", function() {
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
    "ContextManagerService", "DataRetrieverService", "$scope", "$rootScope", "$log", "storage", "geolocation", function(ContextManagerService, DataRetrieverService, $scope, $rootScope, $log, storage, geolocation) {
      var ctn, uri, _ref;
      $scope.stack = {};
      $scope.observers = {};
      geolocation.getLocation().then(function(data) {
        $log.info("User location detected: longitude " + data.coords.longitude + " latitude " + data.coords.latitude);
        ContextManagerService.addUserProperty("lat", data.coords.latitude);
        ContextManagerService.addUserProperty("lng", data.coords.longitude);
        return $scope.updateStack();
      });
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
      $scope.updateStack = function() {
        var id, newOrigin, origin, _ref1, _results;
        _ref1 = $scope.stack;
        _results = [];
        for (id in _ref1) {
          origin = _ref1[id];
          newOrigin = ContextManagerService.rewriteOrigin(id, $scope.observers[id]);
          _results.push($scope.stack[id] = newOrigin);
        }
        return _results;
      };
      $rootScope.$on("notifyUserInteraction", function(event, action, item) {
        ContextManagerService.trackUserInteraction(action, item);
        $log.info("Context updated! Let's update the page stack accordingly!");
        return $scope.updateStack();
      });
      return $rootScope.$on("containerAdded", function(event, ctnOrigin, ctnObserver) {
        $log.debug("Added ctn " + ctnOrigin + " reactive to " + ctnObserver);
        $scope.stack[ctnOrigin] = ctnOrigin;
        return $scope.observers[ctnOrigin] = ctnObserver;
      });
    }
  ]).service("ContextManagerService", [
    "$log", "$window", function($log, $window) {
      var service;
      service = {
        _context: {
          userProperties: [],
          userInteractions: {}
        }
      };
      service.getContext = function() {
        return this._context;
      };
      service.addUserProperty = function(k, v) {
        return this._context.userProperties.push([k, v]);
      };
      service.trackUserInteraction = function(action, item) {
        this._context.userInteractions = {
          'action': action,
          'item': item
        };
        $log.debug("Going to notify userInteraction to analytics!");
        if (typeof $window.ga === "function") {
          $window.ga("send", "event", "userInteraction", action, item.id);
        }
        return true;
      };
      service.rewriteOrigin = function(origin, observers) {
        var chunks, property, _i, _len, _ref;
        chunks = [];
        if (__indexOf.call(observers, "userProperties") >= 0) {
          _ref = this._context.userProperties;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            property = _ref[_i];
            chunks.push(property.join('='));
          }
        }
        if (__indexOf.call(observers, "userInteractions") >= 0 && this._context.userInteractions.item) {
          chunks.push(["contentId", this._context.userInteractions.item.id].join('='));
        }
        if (chunks.length > 0) {
          origin = origin.replace(".json", "---" + (chunks.join('&')) + ".json");
          return origin;
        }
        return origin;
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
      service.prepareHttpRequest = function(ctnOrigin) {
        var config;
        config = {
          url: ctnOrigin,
          method: 'GET'
        };
        if (/^(http|https):\/\//.test(ctnOrigin)) {
          config.method = 'JSONP';
          config.params = {
            callback: "JSON_CALLBACK"
          };
        }
        $log.info("Going to request " + ctnOrigin + " with method " + config.method);
        return config;
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
          $http(this.prepareHttpRequest(ctnOrigin)).success(function(ctn) {
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
          listening: "@",
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
          if (scope.listening) {
            observers = scope.listening.split(',');
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
              template = "<!-- Current container uri: " + currentOrigin + " -->  \n<wl-" + scope.container.skin + " items=\"container.items\"></wl-" + scope.container.skin + "\">";
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

  angular.module("wordlift.ui.skins.foundation", ["wordlift.containers.engine"]).directive("wlTilesWithThumbsLoop", [
    "$log", function($log) {
      return {
        restrict: "E",
        scope: {
          items: "="
        },
        template: "<div class=\"row\">\n  <ul class=\"small-block-grid-2 large-block-grid-4\">\n    <li ng-repeat=\"item in items\">\n      <wl-item item=\"item\"></wl-item>\n    </li>\n  </ul>\n</div>"
      };
    }
  ]).directive("wlItem", [
    "$log", function($log) {
      return {
        restrict: "E",
        require: "^wlContainer",
        scope: {
          item: "="
        },
        template: "<wl-thumb ng-mouseover=\"container.notifier('read', item)\"></wl-thumb>\n<wl-item-property name=\"title\" emphasis=\"title\"></wl-item-property>\n<wl-item-property name=\"content\" emphasis=\"paragraph\"></wl-item-property>\n<wl-link-to-item label=\"More info\" emphasis=\"paragraph\"></wl-link-to-item>",
        link: function(scope, element, attrs, ctrl) {
          return scope.container = ctrl;
        }
      };
    }
  ]).constant("emphasisLevels", {
    'title': 'h5',
    'paragraph': 'p'
  }).directive("wlItemProperty", [
    "$log", "emphasisLevels", function($log, emphasisLevels) {
      return {
        restrict: "E",
        scope: false,
        template: function(tElement, tAttrs) {
          var tag;
          tag = emphasisLevels[tAttrs.emphasis];
          if (tag == null) {
            tag = 'span';
          }
          return "<" + tag + " ng-show=\"item." + tAttrs.name + "\" class=\"item-" + tAttrs.name + "\">{{item." + tAttrs.name + "}}</" + tag + ">";
        }
      };
    }
  ]).directive("wlLinkToItem", [
    "$log", "emphasisLevels", function($log, emphasisLevels) {
      return {
        restrict: "E",
        scope: false,
        template: function(tElement, tAttrs) {
          var tag;
          tag = emphasisLevels[tAttrs.emphasis];
          if (tag == null) {
            tag = 'span';
          }
          return "<" + tag + " ng-show=\"item.uri\" class=\"item-uri\"><a ng-href=\"{{item.uri}}\">" + tAttrs.label + "</a></" + tag + ">";
        }
      };
    }
  ]).directive("wlThumb", [
    "$log", function($log) {
      return {
        restrict: "E",
        scope: false,
        template: function(tElement, tAttrs) {
          return "<img ng-show=\"item.thumbnail\" class=\"item-thumbnail\" ng-src=\"{{item.thumbnail}}\" />";
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
