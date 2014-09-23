(function() {
  window.containers = {};

  $(document).ready(function() {
    var injector;
    angular.module("shoof", ["wordlift.ui.skins.famous"]);
    return injector = angular.bootstrap(document, ["shoof"]);
  });

}).call(this);

//# sourceMappingURL=famous-starter.js.map
