(function() {
  var $;

  $ = jQuery;

  window.containers = {};

  $(document).ready(function() {
    var injector;
    $('body').attr("ng-controller", "wlContainersEngineCtrl");
    angular.module("shoof", ["wordlift.ui.skins.famous"]);
    return injector = angular.bootstrap(document, ["shoof"]);
  });

}).call(this);

//# sourceMappingURL=famous-starter.js.map
