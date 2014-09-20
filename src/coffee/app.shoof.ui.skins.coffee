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
        <ul>
          <li ng-repeat="item in items">
            <div>{{item.title}}</div>
          </li>
        </ul>
      """
    )
]

# Skin directive for Video
app.directive "wlVideo", [
  "$compile"
  "$injector"
  "$sce"
  ($compile, $injector, $sce) ->
    return (
      restrict: "E"
      scope:
        items: "="
      link: (scope, element, attrs) ->
        scope.trustSrc = (src) ->
          $sce.trustAsResourceUrl(src)
      template: """
        <ul ng-repeat="item in items">
          <li>
            <div>{{item.title}}</div>
            <div class="flex-video">
               <iframe width="300" height="250" ng-src="{{trustSrc(item.meta.videoURL)}}" frameborder="0" allowfullscreen></iframe>
            </div>
          </li>
        </ul>
      """
    )
]