# Define window.containers: it's the storage for in-page loaded containers
window.containers = {}
# Once the page is loaded, angula app is bootstraped
$( document ).ready ()->
  angular.module("containerBasedApp",["wordlift.ui.skins.foundation"])
  injector = angular.bootstrap(document, ["containerBasedApp"])