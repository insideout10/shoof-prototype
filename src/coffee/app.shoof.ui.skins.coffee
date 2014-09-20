# Sample skin directive for news
app.directive "wlNews", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      scope:
        items: "="
      link: (scope, element, attrs) ->
        scope.notify = (item) ->
          $log.debug "Clicked on video #{item.id}"
          scope.$emit "contextChanged", "contentId", item.id
      template: """
        <ul class="small-block-grid-2 large-block-grid-2">
          <li ng-repeat="item in items">
            <img ng-src="{{item.meta.thumb}}" ng-mouseover="notify(item)" />
            <h5>{{item.title}}</h5>
            <p>
            {{item.content}}<br />[ <a ng-href="{{item.content}}">More Info</a> ]
            </p>
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
  "$log"
  ($compile, $injector, $sce, $log) ->
    return (
      restrict: "E"
      scope:
        items: "="
      link: (scope, element, attrs) ->
        scope.trustSrc = (src) ->
          $sce.trustAsResourceUrl(src)
        scope.notify = (item) ->
          $log.debug "Clicked on video #{item.id}"
          scope.$emit "contextChanged", "contentId", item.id
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