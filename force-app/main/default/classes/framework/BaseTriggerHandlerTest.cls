@isTest
private class BaseTriggerHandlerTest {

    // Mock implementation of BaseTriggerHandler for testing purposes
    private class MockBaseHandler extends framework.BaseTriggerHandler {
        public Boolean lifecycleMethodCalled = false; // Indicates if any lifecycle method was invoked

        public MockBaseHandler(TriggerOperation operationType, List<SObject> newRecords, List<SObject> oldRecords, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
            super(operationType, newRecords, oldRecords, newMap, oldMap);
        }

        // Implement all abstract methods from BaseTriggerHandler
        protected override void beforeInsert() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.beforeInsert called.'); }
        protected override void afterInsert() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.afterInsert called.'); }
        protected override void beforeUpdate() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.beforeUpdate called.'); }
        protected override void afterUpdate() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.afterUpdate called.'); }
        protected override void beforeDelete() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.beforeDelete called.'); }
        protected override void afterDelete() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.afterDelete called.'); }
        protected override void afterUndelete() { lifecycleMethodCalled = true; System.debug('MockBaseHandler.afterUndelete called.'); }
    }

    // Helper to reset static variables of BaseTriggerHandler before each test that needs it.
    private static void resetBaseTriggerHandlerStatics() {
        framework.BaseTriggerHandler.bypassAllTriggers = false;
        framework.BaseTriggerHandler.processedContexts.clear();
    }

    @isTest
    static void testBypassAllTriggersFlag() {
        resetBaseTriggerHandlerStatics(); // Ensure clean state

        // --- Test case 1: bypassAllTriggers = true ---
        framework.BaseTriggerHandler.bypassAllTriggers = true;

        // Create mock SObjects (can be any SObject type as BaseTriggerHandler is generic)
        List<SObject> mockNewRecords = new List<SObject>{ new Account(Name = 'Test Account') };
        
        MockBaseHandler handlerBypassed = new MockBaseHandler(TriggerOperation.BEFORE_INSERT, mockNewRecords, null, null, null);
        
        Test.startTest();
        handlerBypassed.run();
        Test.stopTest();

        Assert.isFalse(handlerBypassed.lifecycleMethodCalled, 'Lifecycle method should NOT be called when bypassAllTriggers is true.');

        // --- Test case 2: bypassAllTriggers = false ---
        framework.BaseTriggerHandler.bypassAllTriggers = false; // Explicitly set to false for this part

        MockBaseHandler handlerNotBypassed = new MockBaseHandler(TriggerOperation.BEFORE_INSERT, mockNewRecords, null, null, null);
        
        Test.startTest();
        handlerNotBypassed.run();
        Test.stopTest();

        Assert.isTrue(handlerNotBypassed.lifecycleMethodCalled, 'Lifecycle method SHOULD be called when bypassAllTriggers is false.');
        
        // Clean up static variable for other tests
        resetBaseTriggerHandlerStatics();
    }

    @isTest
    static void testRecursionControl() {
        resetBaseTriggerHandlerStatics(); // Ensure clean state (bypass is false, processedContexts is clear)

        List<SObject> mockNewRecords = new List<SObject>{ new Account(Name = 'Test Account Recursion') };
        TriggerOperation operation = TriggerOperation.BEFORE_INSERT; // Same operation for both handlers

        // --- First call to handler ---
        MockBaseHandler handler1 = new MockBaseHandler(operation, mockNewRecords, null, null, null);
        
        Test.startTest();
        handler1.run();
        Test.stopTest();

        Assert.isTrue(handler1.lifecycleMethodCalled, 'Handler1: Lifecycle method should be called for the first run.');
        Assert.isTrue(framework.BaseTriggerHandler.processedContexts.contains(String.valueOf(operation)), 
                      'Handler1: Context ID for ' + operation + ' should be in processedContexts.');

        // --- Second call to handler with the same context (operationType) ---
        // (lifecycleMethodCalled is an instance variable, so handler2 will have its own)
        MockBaseHandler handler2 = new MockBaseHandler(operation, mockNewRecords, null, null, null); 
        
        Test.startTest();
        handler2.run();
        Test.stopTest();

        Assert.isFalse(handler2.lifecycleMethodCalled, 
                       'Handler2: Lifecycle method should NOT be called due to recursion control for operation: ' + operation);
        
        // Clean up static variable for other tests
        resetBaseTriggerHandlerStatics();
    }
}
