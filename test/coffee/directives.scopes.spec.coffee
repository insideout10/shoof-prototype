angular.module("fakeApp",[])
  .directive("container", ($rootScope)->
    restrict: "E"
    scope:
      item: "="
    template: """
      <with-scope></with-scope>
      <with-isolate-scope item="item"></with-isolate-scope>
      <without-scope></without-scope>      
    """
    link: (scope, element, attrs) ->
      $rootScope.$broadcast "containerLoaded", scope
  )
  .directive("withScope", ($rootScope)->
    restrict: "E"
    scope: true
    link: (scope, element, attrs) ->
      $rootScope.$broadcast "withScopeLoaded", scope
  )
  .directive("withoutScope", ($rootScope)->
    restrict: "E"
    scope: false # Default value for custom directives
    link: (scope, element, attrs) ->
      $rootScope.$broadcast "withoutScopeLoaded", scope
  )
  .directive("withIsolateScope", ($rootScope)->
    restrict: "E"
    scope:
      item: '='
    link: (scope, element, attrs) ->
      $rootScope.$broadcast "withIsolatedLoaded", scope

  )

describe "ui.skin directives", ->
  
  scope = undefined
  element = undefined 

  # Tests set-up.
  beforeEach module('fakeApp')
  beforeEach inject(($rootScope) ->
    scope = $rootScope.$new()    
    # Fake dom
    element = angular.element """
      <container item="item"></container>
    """
    # Set spy on $emit
    spyOn $rootScope, '$broadcast'
  )

  it "check how directives manage the scope depending on scope configuration", inject(($compile, $rootScope) ->

    # Define a fake item
    scope.item = 
      foo: 'bar'
      id: '35'

    # Define a fake item
    scope.dupItem = 
      foo: 'bar'
      id: '35'

    # Compile the directive
    $compile(element)(scope)
    scope.$digest()

    expect($rootScope.$broadcast).toHaveBeenCalled()
    expect($rootScope.$broadcast.calls.count()).toEqual(4)
    

    withScopeScope = $rootScope.$broadcast.calls.argsFor(0)[1]
    withIsolateScopeScope = $rootScope.$broadcast.calls.argsFor(1)[1]
    withoutScopeScope = $rootScope.$broadcast.calls.argsFor(2)[1]
    containerScope = $rootScope.$broadcast.calls.argsFor(3)[1]
    
    # Compare directive scopes
    # <without-scope> $scope is the <container> $scope
    expect((withoutScopeScope.$id is containerScope.$id)).toEqual true
    # <without-scope> $scope.item is defined and is the same object 
    expect(withoutScopeScope.item).not.toBe undefined
    expect((withoutScopeScope.item is scope.item)).toEqual true
    # Control check
    expect((withoutScopeScope.item is scope.dupItem)).toEqual false
    
    # <with-scope> $scope is a new scope
    expect((withScopeScope.$id is containerScope.$id)).toEqual false
    # Its parent is the <container> $scope
    expect((withScopeScope.$parent.$id is containerScope.$id)).toEqual true
    # <with-scope> $scope.item is defined and is the same object 
    expect(withScopeScope.item).not.toBe undefined
    expect((withScopeScope.item is scope.item)).toEqual true
    # Control check
    expect((withScopeScope.item is scope.dupItem)).toEqual false

    # <with-isolate-scope> $scope is a new scope
    expect((withIsolateScopeScope.$id is containerScope.$id)).toEqual false
    # Its parent is the <container> $scope
    expect((withIsolateScopeScope.$parent.$id is containerScope.$id)).toEqual true
    # <with-isolate-scope> $scope.item is defined and is still the same object 
    expect(withIsolateScopeScope.item).not.toBe undefined
    expect((withIsolateScopeScope.item is scope.item)).toEqual true
    # Control check
    expect((withIsolateScopeScope.item is scope.dupItem)).toEqual false
    
      
  )