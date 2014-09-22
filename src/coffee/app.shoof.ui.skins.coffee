# Sample skin directive for news
app.directive "wlNews", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope:
        items: "="
      template: """
        <ul class="small-block-grid-2 large-block-grid-2">
          <li ng-repeat="item in items">
            <img ng-src="{{item.meta.thumb}}" ng-mouseover="container.notifier('read', item)" />
            <h5>{{item.title}}</h5>
            <p>
            {{item.content}}<br />[ <a ng-href="{{item.content}}">More Info</a> ]
            </p>
          </li>
        </ul>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl

    )
]

# Skin directive for Video
app.directive "wlVideo", [
  "$sce"
  "$log"
  ($sce, $log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope:
        items: "="
      template: """
        <div ng-repeat="item in items">
            <h3>{{item.title}}</h3>
            <div class="flex-video">
               <iframe ng-src="{{trustSrc(item.meta.videoURL)}}" frameborder="0" allowfullscreen></iframe>
            </div>
        </div>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl
        scope.trustSrc = (src) ->
          $sce.trustAsResourceUrl(src)
    )
]