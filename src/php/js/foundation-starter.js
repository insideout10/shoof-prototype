(function() {
  window.containers = {};

  $(document).ready(function() {
    var injector;
    $('body').attr("ng-controller", "wlContainersEngineCtrl");
    angular.module("containerBasedApp", ["wordlift.ui.skins.foundation"]);
    return injector = angular.bootstrap(document, ["containerBasedApp"]);
  });

}).call(this);

//# sourceMappingURL=foundation-starter.js.map
