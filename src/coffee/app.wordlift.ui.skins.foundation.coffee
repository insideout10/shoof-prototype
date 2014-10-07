# Sample skin directive for news
angular.module("wordlift.ui.skins.foundation", ["wordlift.containers.engine"])
.directive "wlTilesWithThumbsLoop", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      scope: 
        items: "="
      template: """
        <div class="row">
          <ul class="small-block-grid-2 large-block-grid-4">
            <li ng-repeat="item in items">
              <wl-item item="item"></wl-item>
            </li>
          </ul>
        </div>
      """
    )
]
.directive "wlItem", [
  "$log"
  ($log) ->
    return (
      restrict: "E"
      require: "^wlContainer"
      scope: 
        item: "="
      template: """
        <wl-thumb ng-mouseover="container.notifier('read', item)"></wl-thumb>
        <wl-item-property name="title" emphasis="title"></wl-item-property>
        <wl-item-property name="content" emphasis="paragraph"></wl-item-property>
        <wl-link-to-item label="More info" emphasis="paragraph"></wl-link-to-item>
      """
      link: (scope, element, attrs, ctrl) ->
        scope.container = ctrl

    )
]
.constant "emphasisLevels", {
  'title': 'h5'
  'paragraph': 'p'
}
.directive "wlItemProperty", [
  "$log", 
  "emphasisLevels",
  ($log, emphasisLevels) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        tag = emphasisLevels[tAttrs.emphasis]
        unless tag?
          tag = 'span'
        """
          <#{tag} ng-show="item.#{tAttrs.name}" class="item-#{tAttrs.name}">{{item.#{tAttrs.name}}}</#{tag}>
        """
    )
]
.directive "wlLinkToItem", [
  "$log", 
  "emphasisLevels",
  ($log, emphasisLevels) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        tag = emphasisLevels[tAttrs.emphasis]
        unless tag?
          tag = 'span'
        """
          <#{tag} ng-show="item.uri" class="item-uri"><a ng-href="{{item.uri}}">#{tAttrs.label}</a></#{tag}>
        """
    )
]

.directive "wlThumb", [
  "$log", 
  ($log) ->
    return (
      restrict: "E"
      scope: false
      template: (tElement, tAttrs) ->
        """
          <img ng-show="item.thumbnail" class="item-thumbnail" ng-src="{{item.thumbnail}}" />
        """
    )
]


# Skin directive for Video
.directive "wlVideo", [
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