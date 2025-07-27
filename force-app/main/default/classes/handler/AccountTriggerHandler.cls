public class AccountTriggerHandler extends framework.BaseTriggerHandler {

    // Used in afterInsert to prevent recursive task creation if account updates could re-trigger this handler.
    @TestVisible 
    private static Set<Id> accountsWithTaskCreated = new Set<Id>();

    public AccountTriggerHandler(TriggerOperation operationType, List<SObject> newRecords, List<SObject> oldRecords, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        super(operationType, newRecords, oldRecords, newMap, oldMap);
    }

    protected override void beforeInsert() {
        List<Account> newAccounts = (List<Account>)this.newRecords;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');

        for (Account acc : newAccounts) {
            if (acc.Name == 'TestReject') {
                acc.Name.addError('Name "TestReject" is not allowed via AccountTriggerHandler.');
            }
        }
    }

    protected override void afterInsert() {
        List<Account> newAccounts = (List<Account>)this.newRecords;
        // Map<Id, Account> newAccountMap = (Map<Id, Account>)this.newMap; // Not strictly needed for this logic but good practice if IDs were used
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');

        List<Task> tasksToInsert = new List<Task>();
        for (Account acc : newAccounts) {
            if (acc.Name == 'TestCreateTask' && !accountsWithTaskCreated.contains(acc.Id)) {
                // Add to set before DML to prevent re-entry for this specific logic
                accountsWithTaskCreated.add(acc.Id);

                Task followUpTask = new Task(
                    Subject = 'Follow up on new Account: ' + acc.Name,
                    WhatId = acc.Id, // Relate to the Account
                    OwnerId = UserInfo.getUserId(), // Assign to current user
                    Status = 'Not Started',
                    Priority = 'Normal'
                );
                tasksToInsert.add(followUpTask);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error inserting follow-up tasks in AccountTriggerHandler: ' + e.getMessage());
                // Optionally, add error handling to the source records if appropriate
            }
        }
    }

    protected override void beforeUpdate() {
        List<Account> newAccounts = (List<Account>)this.newRecords;
        List<Account> oldAccounts = (List<Account>)this.oldRecords;
        Map<Id, Account> newAccountMap = (Map<Id, Account>)this.newMap;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>)this.oldMap;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');
        // Future logic for beforeUpdate
    }

    protected override void afterUpdate() {
        List<Account> newAccounts = (List<Account>)this.newRecords;
        List<Account> oldAccounts = (List<Account>)this.oldRecords;
        Map<Id, Account> newAccountMap = (Map<Id, Account>)this.newMap;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>)this.oldMap;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');
        // Future logic for afterUpdate
    }

    protected override void beforeDelete() {
        List<Account> oldAccounts = (List<Account>)this.oldRecords;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>)this.oldMap;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');
        // Future logic for beforeDelete
    }

    protected override void afterDelete() {
        List<Account> oldAccounts = (List<Account>)this.oldRecords;
        Map<Id, Account> oldAccountMap = (Map<Id, Account>)this.oldMap;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');
        // Future logic for afterDelete
    }

    protected override void afterUndelete() {
        List<Account> newAccounts = (List<Account>)this.newRecords; // In afterUndelete, Trigger.new contains the undeleted records
        // Map<Id, Account> newAccountMap = (Map<Id, Account>)this.newMap;
        System.debug('AccountTriggerHandler.' + this.operationType + ' called.');
        // Future logic for afterUndelete
    }
}
