# Sample skin directive for news
angular.module("wordlift.ui.skins.famous", ["famous.angular", "ngRoute", "wordlift.containers.engine"])
.directive "wlNews", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope:
        items: "="
      template: """
        <fa-app style="height: 200px">
          <fa-surface fa-background-color="'red'">Hello world</fa-surface>
        </fa-app>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl

    )
]