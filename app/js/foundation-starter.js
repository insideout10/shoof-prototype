(function() {
  window.containers = {};

  $(document).ready(function() {
    var injector;
    angular.module("shoof", ["wordlift.ui.skins.foundation"]);
    return injector = angular.bootstrap(document, ["shoof"]);
  });

}).call(this);

//# sourceMappingURL=foundation-starter.js.map
