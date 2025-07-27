public class CustomSettingsService {

    // Private constructor as all methods are static
    private CustomSettingsService() {}

    /**
     * Retrieves all records for a given List Custom Setting API name.
     * @param customSettingApiName The API name of the List Custom Setting (e.g., 'My_Settings__c').
     * @return A Map<String, SObject> where the key is the 'Name' of the custom setting record 
     *         and the value is the custom setting sObject record itself. Returns an empty map if errors occur or if the name is blank.
     * @throws AuraHandledException if there's an error during the query or if the custom setting type is not found.
     */
    public static Map<String, SObject> getAllSettings(String customSettingApiName) {
        if (String.isBlank(customSettingApiName)) {
            System.debug(LoggingLevel.WARN, 'Custom Settings API Name cannot be blank.');
            return new Map<String, SObject>(); // Or throw new AuraHandledException('Custom Setting API Name cannot be blank.');
        }

        // Sanitize the API name to prevent SOQL injection
        String sanitizedApiName = String.escapeSingleQuotes(customSettingApiName);

        // Dynamically get all fields for the SObject type
        String fields = '';
        try {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sanitizedApiName.toLowerCase()).getDescribe().fields.getMap();
            if (fieldMap == null || fieldMap.isEmpty()) {
                 throw new AuraHandledException('No fields found for SObject type: ' + sanitizedApiName + '. Ensure it is a valid Custom Setting API name.');
            }
            fields = String.join(new List<String>(fieldMap.keySet()), ',');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error describing custom setting SObject: ' + sanitizedApiName + '. Details: ' + e.getMessage());
            throw new AuraHandledException('Error describing custom setting SObject: ' + sanitizedApiName + '. Ensure it is a valid API name. Details: ' + e.getMessage());
        }
        
        if (String.isBlank(fields)) { // Should not happen if previous try-catch didn't throw but as a safeguard.
            throw new AuraHandledException('Could not determine fields for SObject type: ' + sanitizedApiName);
        }

        String query = 'SELECT ' + fields + ' FROM ' + sanitizedApiName;
        Map<String, SObject> settingsMap = new Map<String, SObject>();

        try {
            List<SObject> settingsList = Database.query(query);
            for (SObject s : settingsList) {
                // Custom settings must have a Name field, but good to check if it's populated
                Object nameValue = s.get('Name');
                if (nameValue != null) {
                    settingsMap.put((String)nameValue, s);
                } else {
                    // Handle records with null Name if necessary, perhaps log or skip
                    System.debug(LoggingLevel.WARN, 'Custom setting record found with null Name for ' + sanitizedApiName + ', ID: ' + s.Id);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching custom settings for ' + sanitizedApiName + ': ' + e.getMessage());
            // Re-throw as AuraHandledException so it can be surfaced in LWC/Aura if needed
            throw new AuraHandledException('Error fetching custom settings for ' + sanitizedApiName + ': ' + e.getMessage());
        }
        return settingsMap;
    }

    /**
     * Retrieves a specific record from a List Custom Setting by its API name and record name.
     * @param customSettingApiName The API name of the List Custom Setting (e.g., 'My_Settings__c').
     * @param settingName The 'Name' of the specific custom setting record.
     * @return The SObject record, or null if not found or if inputs are blank.
     * @throws AuraHandledException if there's an error during the query or if the custom setting type is not found.
     */
    public static SObject getSetting(String customSettingApiName, String settingName) {
        if (String.isBlank(customSettingApiName) || String.isBlank(settingName)) {
            System.debug(LoggingLevel.WARN, 'Custom Settings API Name and Setting Name cannot be blank.');
            return null; // Or throw new AuraHandledException('Custom Setting API Name and Setting Name cannot be blank.');
        }

        // Sanitize inputs
        String sanitizedApiName = String.escapeSingleQuotes(customSettingApiName);
        String sanitizedSettingName = String.escapeSingleQuotes(settingName); // settingName is used in WHERE clause

        // Dynamically get all fields
        String fields = '';
         try {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sanitizedApiName.toLowerCase()).getDescribe().fields.getMap();
            if (fieldMap == null || fieldMap.isEmpty()) {
                 throw new AuraHandledException('No fields found for SObject type: ' + sanitizedApiName + '. Ensure it is a valid Custom Setting API name.');
            }
            fields = String.join(new List<String>(fieldMap.keySet()), ',');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error describing custom setting SObject: ' + sanitizedApiName + '. Details: ' + e.getMessage());
            throw new AuraHandledException('Error describing custom setting SObject: ' + sanitizedApiName + '. Ensure it is a valid API name. Details: ' + e.getMessage());
        }

        if (String.isBlank(fields)) {
             throw new AuraHandledException('Could not determine fields for SObject type: ' + sanitizedApiName);
        }

        String query = 'SELECT ' + fields + ' FROM ' + sanitizedApiName +
                       ' WHERE Name = \'' + sanitizedSettingName + '\' LIMIT 1'; // Bind variables not directly supported in dynamic query string for WHERE value like this, must concatenate or use Database.queryWithBinds

        // Using Database.queryWithBinds for better security and handling of special characters in settingName
        Map<String, Object> bindVars = new Map<String, Object>{'settingNameValue' => settingName};
        query = 'SELECT ' + fields + ' FROM ' + sanitizedApiName +
                       ' WHERE Name = :settingNameValue LIMIT 1';


        try {
            List<SObject> settingsList = Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE); // Or SYSTEM_MODE depending on requirements
            return settingsList.isEmpty() ? null : settingsList[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching custom setting "' + settingName + '" from ' + sanitizedApiName + ': ' + e.getMessage());
            throw new AuraHandledException('Error fetching custom setting "' + settingName + '" for ' + sanitizedApiName + ': ' + e.getMessage());
        }
    }
}
