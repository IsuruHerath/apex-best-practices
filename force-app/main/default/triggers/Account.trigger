trigger AccountTrigger on Account (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
    // Optionally set bypass for specific contexts if needed, e.g., for testing other automation.
    // framework.BaseTriggerHandler.bypassAllTriggers = false;

    // Instantiate the handler by passing Trigger context variables
    framework.ITriggerHandler handler = new handler.AccountTriggerHandler(
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );

    // Execute the handler logic
    handler.run();
}
