# Sample skin directive for news
app.directive "wlNews", [
  "$compile"
  "$injector"
  ($compile, $injector) ->
    return (
      restrict: "E"
      scope:
        items: "="
      template: """
        <ul ng-repeat="item in items">
          <li>
            <div>{{item.title}}</div>
          </li>
        </ul>
      """
    )
]