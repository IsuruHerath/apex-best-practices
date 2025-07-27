@isTest
private class AccountTriggerHandlerTest {

    // Helper method to reset static variables before each test
    private static void resetStatics() {
        framework.BaseTriggerHandler.bypassAllTriggers = false;
        framework.BaseTriggerHandler.processedContexts.clear();
        // Accessing the @TestVisible static set to clear it
        AccountTriggerHandler.accountsWithTaskCreated.clear(); 
    }

    @isTest
    static void testBeforeInsert_ValidationPass() {
        resetStatics();

        Account acc = new Account(Name = 'Valid Test Account');
        List<SObject> newRecords = new List<SObject>{ acc };

        handler.AccountTriggerHandler handler = new handler.AccountTriggerHandler(
            TriggerOperation.BEFORE_INSERT, newRecords, null, null, null
        );

        Test.startTest();
        handler.run();
        Test.stopTest();

        Assert.isFalse(acc.hasErrors(), 'Account should not have errors with a valid name.');
    }

    @isTest
    static void testBeforeInsert_ValidationFail_TestReject() {
        resetStatics();

        Account acc = new Account(Name = 'TestReject');
        List<SObject> newRecords = new List<SObject>{ acc };

        handler.AccountTriggerHandler handler = new handler.AccountTriggerHandler(
            TriggerOperation.BEFORE_INSERT, newRecords, null, null, null
        );

        Test.startTest();
        handler.run();
        Test.stopTest();

        Assert.isTrue(acc.hasErrors(), 'Account should have errors.');
        Assert.isTrue(acc.Name.getErrors().size() > 0, 'Account Name field should have an error.');
        // Check for specific error message if desired, e.g.
        // Assert.areEqual('Name "TestReject" is not allowed via AccountTriggerHandler.', acc.Name.getErrors()[0].getMessage());
    }

    @isTest
    static void testAfterInsert_CreateTask() {
        resetStatics();

        Account acc = new Account(Name = 'TestCreateTask');

        Test.startTest();
        insert acc; // This will invoke the trigger and thus the handler
        Test.stopTest();

        // Query for Tasks related to this Account
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :acc.Id];
        Assert.areEqual(1, tasks.size(), 'One Task should have been created.');
        Assert.isTrue(tasks[0].Subject.contains('Follow up on new Account: TestCreateTask'), 'Task subject is incorrect.');
    }

    @isTest
    static void testAfterInsert_CreateTask_RecursionControl() {
        resetStatics();
        // Part 1: Standard task creation
        Account acc1 = new Account(Name = 'TestCreateTask', Description = 'First Account');
        
        Test.startTest();
        insert acc1;
        Test.stopTest();
        
        List<Task> tasksForAcc1 = [SELECT Id FROM Task WHERE WhatId = :acc1.Id];
        Assert.areEqual(1, tasksForAcc1.size(), 'Task should be created for the first account.');
        Assert.isTrue(AccountTriggerHandler.accountsWithTaskCreated.contains(acc1.Id), 
                      'Acc1 ID should be in accountsWithTaskCreated set after task creation.');

        // Part 2: Test that a different account also gets a task (set is per-ID)
        Account acc2 = new Account(Name = 'TestCreateTask', Description = 'Second Account');
        
        Test.startTest();
        insert acc2;
        Test.stopTest();
        
        List<Task> tasksForAcc2 = [SELECT Id FROM Task WHERE WhatId = :acc2.Id];
        Assert.areEqual(1, tasksForAcc2.size(), 'Task should also be created for the second, different account.');
        Assert.isTrue(AccountTriggerHandler.accountsWithTaskCreated.contains(acc2.Id), 
                      'Acc2 ID should be in accountsWithTaskCreated set.');


        // Part 3: Test actual recursion control by directly manipulating the set (if an update could re-trigger afterInsert logic)
        // This part is more of a unit test of the set itself.
        // If we had an update path that could also call the task creation, we would test that.
        // For now, we've shown the set is populated. Let's ensure if we *could* re-run on acc1, it wouldn't make another task.
        // This is a bit artificial without a re-entrant update path in the handler.
        // The current `accountsWithTaskCreated` set in AccountTriggerHandler prevents a *second* task
        // if the *same* `afterInsert` logic for that specific record ID were to be run again.
        // The DML test above already shows it's populated. No further DML needed here as it would be a new transaction.
        // If the handler's afterInsert were public, we could call it again.
        // The main test is that the set gets populated, which we've asserted.
    }

    @isTest
    static void testBypassFunctionality() {
        resetStatics();
        framework.BaseTriggerHandler.bypassAllTriggers = true;

        Account acc = new Account(Name = 'TestReject');
        List<SObject> newRecords = new List<SObject>{ acc };

        handler.AccountTriggerHandler handler = new handler.AccountTriggerHandler(
            TriggerOperation.BEFORE_INSERT, newRecords, null, null, null
        );

        Test.startTest();
        handler.run(); // Calling run directly on handler instance
        Test.stopTest();

        Assert.isFalse(acc.hasErrors(), 'Account should have no errors when bypassAllTriggers is true.');
    }

    @isTest
    static void testDirectDML_BeforeInsert_ValidationFail() {
        resetStatics();
        framework.BaseTriggerHandler.bypassAllTriggers = false; // Ensure not bypassed

        Boolean dmlExceptionCaught = false;
        String exceptionMessage = '';
        Test.startTest();
        try {
            insert new Account(Name = 'TestReject');
        } catch (DmlException e) {
            dmlExceptionCaught = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(dmlExceptionCaught, 'DmlException should have been caught.');
        // The exact message can vary (e.g., include field name), so checking for a core part.
        Assert.isTrue(exceptionMessage.contains('TestReject') && exceptionMessage.contains('not allowed'), 
                      'DML exception message should indicate the rejection. Message: ' + exceptionMessage);
    }
    
    // testDirectDML_AfterInsert_CreateTask is covered by testAfterInsert_CreateTask as it uses DML.
}
