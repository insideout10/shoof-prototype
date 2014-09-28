$ = jQuery
# Define window.containers: it's the storage for in-page loaded containers
window.containers = {}
# Once the page is loaded, angula app is bootstraped
$( document ).ready ()->
  # Add angular controller to the body element
  $('body').attr "ng-controller", "wlContainersEngineCtrl"
  # Create the angular app
  angular.module("containerBasedApp",["wordlift.ui.skins.foundation"])
  # and finally perform angular app bootstrap
  
  injector = angular.bootstrap(document, ["containerBasedApp"])