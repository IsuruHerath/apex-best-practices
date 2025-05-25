public abstract class BaseTriggerHandler implements ITriggerHandler {

    // Trigger context variables
    protected TriggerOperation operationType;
    protected List<SObject> newRecords;
    protected List<SObject> oldRecords;
    protected Map<Id, SObject> newMap;
    protected Map<Id, SObject> oldMap;

    // Basic recursion control
    public static Set<String> processedContexts = new Set<String>();

    // Bypass all triggers flag
    public static Boolean bypassAllTriggers = false;

    /**
     * Constructor to initialize trigger context variables.
     * @param operationType The type of trigger operation.
     * @param newRecords The list of new sObject records.
     * @param oldRecords The list of old sObject records.
     * @param newMap The map of new sObject records by ID.
     * @param oldMap The map of old sObject records by ID.
     */
    public BaseTriggerHandler(TriggerOperation operationType, List<SObject> newRecords, List<SObject> oldRecords, Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {
        this.operationType = operationType;
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    /**
     * Main execution method for the trigger handler.
     * Manages bypass logic, recursion control, and dispatches to lifecycle methods.
     */
    public virtual void run() { // Made virtual so subclasses can override the entire run sequence if absolutely necessary, though typically they'd just implement lifecycle methods.
        if (bypassAllTriggers) {
            return;
        }

        // Context ID for recursion control.
        // A more robust ID might include SObjectType if this base handler is very generic.
        // For now, assuming it's extended by SObject-specific handlers, operationType is a start.
        // If this handler is intended for a specific SObject (via extension), the class name itself can be part of context.
        String contextId = String.valueOf(this.operationType); // Using String.valueOf for safety, though .name() is typical for enums.
        // For a more specific context tied to the concrete handler, one might use:
        // String contextId = this.toString() + '.' + String.valueOf(this.operationType);


        if (processedContexts.contains(contextId)) {
            System.debug(LoggingLevel.WARN, 'Recursion detected for context: ' + contextId + '. Skipping further execution in this handler.');
            return;
        }

        processedContexts.add(contextId);

        // Dispatch to appropriate lifecycle method
        switch on this.operationType {
            when BEFORE_INSERT {
                beforeInsert();
            }
            when AFTER_INSERT {
                afterInsert();
            }
            when BEFORE_UPDATE {
                beforeUpdate();
            }
            when AFTER_UPDATE {
                afterUpdate();
            }
            when BEFORE_DELETE {
                beforeDelete();
            }
            when AFTER_DELETE {
                afterDelete();
            }
            when AFTER_UNDELETE {
                afterUndelete();
            }
            // No 'when else' needed as TriggerOperation is a well-defined enum.
        }
        
        // Regarding removal from processedContexts:
        // For many trigger recursion patterns, we want to prevent re-entry for the entire transaction
        // for a given operation type (e.g., all Account after update logic).
        // If granular control is needed (e.g. allow a specific nested operation once),
        // a more complex context ID and management strategy would be required.
        // For this base handler, not removing it means this specific handler (and operation) won't run again.
    }

    // Abstract lifecycle methods to be implemented by subclasses
    protected abstract void beforeInsert();
    protected abstract void afterInsert();
    protected abstract void beforeUpdate();
    protected abstract void afterUpdate();
    protected abstract void beforeDelete();
    protected abstract void afterDelete();
    protected abstract void afterUndelete();
}
