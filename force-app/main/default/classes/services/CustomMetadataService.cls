public class CustomMetadataService {

    // Private constructor as all methods are static
    private CustomMetadataService() {}

    /**
     * Retrieves all records for a given Custom Metadata Type API name.
     * @param cmdtApiName The API name of the Custom Metadata Type (e.g., 'My_CMDT__mdt').
     * @return A List<SObject> containing all records of that CMD type.
     * @throws AuraHandledException if cmdtApiName is blank, if no queryable fields are found, 
     *         or if there's an error during the query or schema calls.
     */
    public static List<SObject> getAllRecords(String cmdtApiName) {
        if (String.isBlank(cmdtApiName)) {
            throw new AuraHandledException('Custom Metadata Type API Name cannot be blank.');
        }
        try {
            // Sanitize API name for use in SOQL (though for FROM clause, less critical than WHERE)
            String sanitizedApiName = String.escapeSingleQuotes(cmdtApiName);

            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sanitizedApiName.toLowerCase()).getDescribe().fields.getMap();
            
            List<String> queryableFields = new List<String>();
            for(String fieldName : fieldMap.keySet()){
                if(fieldMap.get(fieldName).getDescribe().isQueryable()){
                     queryableFields.add(fieldName);
                }
            }
            
            if (queryableFields.isEmpty()) {
                 throw new AuraHandledException('No queryable fields found for Custom Metadata Type: ' + sanitizedApiName);
            }

            String fields = String.join(queryableFields, ',');
            String query = 'SELECT ' + fields + ' FROM ' + sanitizedApiName; // Using sanitizedApiName here
            
            // Custom Metadata Types are typically accessed in System Mode, but respecting context if ever needed.
            // For CMDs, AccessLevel.USER_MODE might not be appropriate as they are part of metadata.
            // Defaulting to system access for CMDs usually makes sense.
            return Database.query(query); 
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching CMD records for ' + cmdtApiName + ': ' + e.getMessage());
            throw new AuraHandledException('Error fetching records for ' + cmdtApiName + '. Ensure API name is correct and accessible. Details: ' + e.getMessage());
        }
    }

    /**
     * Retrieves a specific record from a Custom Metadata Type by its API name and DeveloperName.
     * @param cmdtApiName The API name of the Custom Metadata Type.
     * @param developerName The DeveloperName of the specific record.
     * @return The SObject record, or null if not found.
     * @throws AuraHandledException if inputs are blank, if no queryable fields are found,
     *         or if there's an error during the query or schema calls.
     */
    public static SObject getRecord(String cmdtApiName, String developerName) {
        if (String.isBlank(cmdtApiName) || String.isBlank(developerName)) {
            throw new AuraHandledException('Custom Metadata Type API Name and Developer Name cannot be blank.');
        }
        try {
            // Sanitize API name
            String sanitizedApiName = String.escapeSingleQuotes(cmdtApiName);

            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sanitizedApiName.toLowerCase()).getDescribe().fields.getMap();
            List<String> queryableFields = new List<String>();
            for(String fieldName : fieldMap.keySet()){
                 if(fieldMap.get(fieldName).getDescribe().isQueryable()){
                     queryableFields.add(fieldName);
                 }
            }

            if (queryableFields.isEmpty()) {
                 throw new AuraHandledException('No queryable fields found for Custom Metadata Type: ' + sanitizedApiName);
            }
            String fields = String.join(queryableFields, ',');

            // Use queryWithBinds to prevent SOQL injection with developerName
            String query = 'SELECT ' + fields + ' FROM ' + sanitizedApiName + // Using sanitizedApiName here
                           ' WHERE DeveloperName = :recordDeveloperName LIMIT 1';
            
            Map<String, Object> bindVars = new Map<String, Object>{
                'recordDeveloperName' => developerName
            };

            // For CMDs, AccessLevel.USER_MODE might not be appropriate.
            // System mode is often assumed for metadata access.
            List<SObject> records = Database.queryWithBinds(query, bindVars, AccessLevel.SYSTEM_MODE); 
            return records.isEmpty() ? null : records[0];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching CMD record ' + developerName + ' for ' + cmdtApiName + ': ' + e.getMessage());
            throw new AuraHandledException('Error fetching record ' + developerName + ' for ' + cmdtApiName + '. Details: ' + e.getMessage());
        }
    }
}
