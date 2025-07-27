public class DescribeService {

    // Private constructor as all methods are static
    private DescribeService() {}

    // Static Caches
    private static Map<String, Schema.DescribeSObjectResult> sObjectDescribeCache = new Map<String, Schema.DescribeSObjectResult>();
    private static Map<String, Schema.DescribeFieldResult> fieldDescribeCache = new Map<String, Schema.DescribeFieldResult>();
    private static Map<String, List<Schema.PicklistEntry>> picklistValuesCache = new Map<String, List<Schema.PicklistEntry>>();

    /**
     * Retrieves the DescribeSObjectResult for a given SObject API name, utilizing a cache.
     * @param sObjectName The API name of the SObject.
     * @return The Schema.DescribeSObjectResult.
     * @throws AuraHandledException if sObjectName is blank or if the SObject type is not found or accessible.
     */
    public static Schema.DescribeSObjectResult getSObjectDescribe(String sObjectName) {
        if (String.isBlank(sObjectName)) {
            throw new AuraHandledException('sObject Name cannot be blank for describe.');
        }
        String cacheKey = sObjectName.toLowerCase();
        if (!sObjectDescribeCache.containsKey(cacheKey)) {
            try {
                Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(cacheKey);
                if (sobjType == null) {
                    // This specific check helps differentiate "not found" from other describe errors.
                    throw new AuraHandledException('SObject type \'' + sObjectName + '\' not found.');
                }
                sObjectDescribeCache.put(cacheKey, sobjType.getDescribe());
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error describing SObject \'' + sObjectName + '\': ' + e.getMessage());
                // If it's already our specific exception, re-throw it, otherwise wrap it.
                if (e instanceof AuraHandledException) throw e; 
                throw new AuraHandledException('Error describing SObject \'' + sObjectName + '\': ' + e.getMessage());
            }
        }
        return sObjectDescribeCache.get(cacheKey);
    }

    /**
     * Retrieves the DescribeFieldResult for a given SObject and field name, utilizing a cache.
     * @param sObjectName The API name of the SObject.
     * @param fieldName The API name of the field.
     * @return The Schema.DescribeFieldResult.
     * @throws AuraHandledException if inputs are blank, or if the SObject/field is not found or accessible.
     */
    public static Schema.DescribeFieldResult getFieldDescribe(String sObjectName, String fieldName) {
        if (String.isBlank(sObjectName) || String.isBlank(fieldName)) {
            throw new AuraHandledException('sObject Name and Field Name cannot be blank for field describe.');
        }
        String cacheKey = (sObjectName + '.' + fieldName).toLowerCase();
        if (!fieldDescribeCache.containsKey(cacheKey)) {
            try {
                Schema.DescribeSObjectResult sObjectResult = getSObjectDescribe(sObjectName); // Leverages sObject cache
                
                // Case-insensitive get from field map
                Map<String, Schema.SObjectField> fieldMap = sObjectResult.fields.getMap();
                Schema.SObjectField sObjectField = fieldMap.get(fieldName.toLowerCase());

                if (sObjectField == null) {
                     throw new AuraHandledException('Field \'' + fieldName + '\' not found on SObject \'' + sObjectName + '\'.');
                }
                Schema.DescribeFieldResult fieldResult = sObjectField.getDescribe();
                fieldDescribeCache.put(cacheKey, fieldResult);
            } catch (Exception e) { 
                System.debug(LoggingLevel.ERROR, 'Error describing field \'' + sObjectName + '.' + fieldName + '\': ' + e.getMessage());
                if (e instanceof AuraHandledException) throw e;
                throw new AuraHandledException('Error describing field \'' + sObjectName + '.' + fieldName + '\': ' + e.getMessage());
            }
        }
        return fieldDescribeCache.get(cacheKey);
    }

    /**
     * Retrieves picklist entries for a given SObject field, utilizing a cache.
     * @param sObjectName The API name of the SObject.
     * @param fieldName The API name of the picklist field.
     * @return A List of Schema.PicklistEntry.
     * @throws AuraHandledException if inputs are blank, SObject/field not found, or field is not a picklist.
     */
    public static List<Schema.PicklistEntry> getPicklistValues(String sObjectName, String fieldName) {
        if (String.isBlank(sObjectName) || String.isBlank(fieldName)) {
            throw new AuraHandledException('sObject Name and Field Name cannot be blank for picklist values.');
        }
        String cacheKey = (sObjectName + '.' + fieldName).toLowerCase();
        if (!picklistValuesCache.containsKey(cacheKey)) {
            try {
                Schema.DescribeFieldResult fieldResult = getFieldDescribe(sObjectName, fieldName); // Leverages field cache
                if (fieldResult.getType() != Schema.DisplayType.PICKLIST && fieldResult.getType() != Schema.DisplayType.MULTIPICKLIST) {
                    throw new AuraHandledException('Field \'' + fieldName + '\' on SObject \'' + sObjectName + '\' is not a picklist or multipicklist field. Actual type: ' + fieldResult.getType());
                }
                List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
                picklistValuesCache.put(cacheKey, values);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error getting picklist values for \'' + sObjectName + '.' + fieldName + '\': ' + e.getMessage());
                 if (e instanceof AuraHandledException) throw e;
                throw new AuraHandledException('Error getting picklist values for \'' + sObjectName + '.' + fieldName + '\': ' + e.getMessage());
            }
        }
        return picklistValuesCache.get(cacheKey);
    }

    /**
     * Clears all static describe caches. Intended for use in test methods.
     */
    @TestVisible
    private static void clearCache() {
        sObjectDescribeCache.clear();
        fieldDescribeCache.clear();
        picklistValuesCache.clear();
    }
}
