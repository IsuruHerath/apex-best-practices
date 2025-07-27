# Salesforce DX Project: Apex Best Practices

This Salesforce DX project demonstrates various Apex best practices, design patterns, and utility services for building robust and scalable Salesforce applications.

## Project Overview and Key Components

This project is structured to provide clear examples of how to implement common patterns and services in Apex. You can explore the `force-app/main/default/classes/` directory to find the source code for these components and their corresponding unit tests.

### Apex Design Patterns Demonstrated:
*   **Builder Pattern (`AccountBuilder.cls`):** Facilitates the creation of complex sObjects (e.g., Accounts for test data) in a readable and fluent way.
*   **Service Layer (`DMLService.cls`, `AccountDMLService.cls`):** Encapsulates DML operations, promoting separation of concerns and including features like security checks. `DMLService` provides a generic base, while `AccountDMLService` offers a specialized implementation for Accounts using the Singleton pattern.

### Apex Utility Services:
*   **`RecordIdService.cls`:** A singleton service for generating mock Salesforce record IDs. This is invaluable for unit testing, allowing for predictable ID generation without actual DML operations.
*   **`ProfileService.cls`:** A singleton service designed for efficient Profile management. It pre-loads and caches all Profile sObjects from the org upon its first use, significantly reducing SOQL queries. Key methods include `getProfileId(String profileName)` to get a profile's ID, `getProfile(String profileName)` to retrieve the full Profile sObject, and `getAllProfiles()` to get a map of all cached profiles.
*   **`CustomSettingsService.cls` (located in `force-app/main/default/classes/services/`)**
    *   **Purpose**: Provides generic methods to access List Custom Setting records dynamically.
    *   **Key Methods**:
        *   `getAllSettings(String customSettingApiName)`: Retrieves all records for a given List Custom Setting.
        *   `getSetting(String customSettingApiName, String settingName)`: Retrieves a specific List Custom Setting record by its name.
*   **`CustomMetadataService.cls` (located in `force-app/main/default/classes/services/`)**
    *   **Purpose**: Provides generic methods to access Custom Metadata Type records dynamically.
    *   **Key Methods**:
        *   `getAllRecords(String cmdtApiName)`: Retrieves all records for a given Custom Metadata Type.
        *   `getRecord(String cmdtApiName, String developerName)`: Retrieves a specific Custom Metadata Type record by its DeveloperName.
*   **`JSONSerializerService.cls` (located in `force-app/main/default/classes/services/`)**
    *   **Purpose**: Provides convenient and robust methods for JSON serialization and deserialization, with error handling.
    *   **Key Methods**:
        *   `serialize(Object objToSerialize, Boolean prettyPrint)`: Serializes an Apex object to a JSON string.
        *   `deserialize(String jsonString, Type targetType)`: Deserializes a JSON string to a specified Apex Type.
        *   `deserializeList(String jsonString, Type targetListItemType)`: Deserializes a JSON array string to a List of a specified Apex Type.
*   **`SOQLQueryBuilder.cls` (located in `force-app/main/default/classes/utilities/`)**
    *   **Purpose**: A fluent API for programmatically constructing and executing SOQL queries. It uses bind variables to help prevent SOQL injection vulnerabilities.
    *   **Key Methods**: `selectFields()`, `selectField()`, `whereEquals()`, `whereIn()`, `orderBy()`, `limitResults()`, `build()`, `execute()`.
*   **`HttpCalloutService.cls` (located in `force-app/main/default/classes/services/`)**
    *   **Purpose**: Simplifies making HTTP callouts (GET, POST, PUT, DELETE) and handling responses. Includes an inner `HttpResponseWrapper` class for easier response management.
    *   **Key Methods**: `get()`, `post()`, `put()`, `deleteCallout()`.
*   **`DescribeService.cls` (located in `force-app/main/default/classes/services/`)**
    *   **Purpose**: Provides cached access to sObject and field describe information (e.g., labels, types, picklist values). This helps optimize performance and reduce governor limit consumption related to describe calls.
    *   **Key Methods**: `getSObjectDescribe()`, `getFieldDescribe()`, `getPicklistValues()`.

## Trigger Handler Framework

### Overview
The Trigger Handler Framework is designed to promote best practices for managing Apex trigger logic. It aims to make trigger code cleaner, more manageable, highly testable, and easily controllable across the application. This approach moves the actual business logic out of the trigger files themselves and into dedicated handler classes.

### Components

*   **`ITriggerHandler.cls` (located in `force-app/main/default/classes/framework/`)**
    *   This interface defines the basic contract for all trigger handlers.
    *   It ensures that every handler has a common entry point by specifying a single public method: `void run();`.

*   **`BaseTriggerHandler.cls` (located in `force-app/main/default/classes/framework/`)**
    *   An abstract class that implements `ITriggerHandler`. It serves as the foundation for all sObject-specific trigger handlers.
    *   **Responsibilities**:
        *   **Trigger Context Storage**: It receives and stores the standard trigger context variables (`Trigger.new`, `Trigger.old`, `Trigger.newMap`, `Trigger.oldMap`, `Trigger.operationType`) in protected instance variables.
        *   **Central Dispatcher**: Its `run()` method acts as a central dispatcher. It first checks for bypass and recursion, then calls the appropriate abstract lifecycle method (e.g., `beforeInsert()`, `afterUpdate()`) based on the current `Trigger.operationType`.
        *   **Bypass Mechanism**: Provides a `public static Boolean bypassAllTriggers` flag that, when set to `true`, will cause all handlers extending `BaseTriggerHandler` to immediately exit their `run()` method. This is useful for data loads or specific Apex operations where trigger logic should be temporarily disabled.
        *   **Recursion Control**: Implements basic recursion control using a `public static Set<String> processedContexts`. It adds a context identifier (based on the trigger operation type) to this set before executing lifecycle methods. If the context is already present, it skips execution for that handler, preventing unwanted recursive loops.

*   **`AccountTriggerHandler.cls` (located in `force-app/main/default/classes/handler/`)**
    *   A concrete implementation of a trigger handler specifically for the `Account` sObject.
    *   It extends `framework.BaseTriggerHandler`, inheriting its context management, bypass, and recursion control features.
    *   It provides the actual business logic by overriding the abstract lifecycle methods (e.g., `beforeInsert()`, `afterInsert()`, `beforeUpdate()`, `afterUpdate()`). For example, in `beforeInsert()`, it might validate Account data, and in `afterInsert()`, it might create related records like Tasks.

### How to Use

The trigger files themselves become very lean. Their primary responsibility is to instantiate the appropriate handler and delegate execution to it.

**Example: `Account.trigger` (located in `force-app/main/default/triggers/`)**
```apex
trigger AccountTrigger on Account (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
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
```

### Benefits

*   **Centralized Logic**: Consolidates all logic for an sObject's triggers into a single handler class, making it easier to find, understand, and maintain.
*   **Bypass Capability**: Allows for easy disabling of all trigger logic when needed (e.g., during data migrations).
*   **Recursion Control**: Provides a built-in mechanism to prevent common recursive trigger scenarios.
*   **Testability**: Handler classes can be instantiated and tested directly in Apex unit tests by mocking trigger context variables, allowing for focused testing of business logic without requiring DML operations.
*   **Readability**: Keeps trigger files minimal and clean, improving overall code readability and maintainability.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
