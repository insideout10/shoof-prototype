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
        <div ng-repeat="item in items">
            <h3>{{item.title}}</h3>
            <div class="flex-video">
               <iframe ng-src="{{trustSrc(item.meta.videoURL)}}" frameborder="0" allowfullscreen></iframe>
            </div>
        </div>
      """
    )
]