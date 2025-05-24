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

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
