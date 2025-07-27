public class JSONSerializerService {

    // Private constructor as all methods are static
    private JSONSerializerService() {}

    /**
     * Serializes an Apex object into a JSON string.
     * @param objToSerialize The object to serialize.
     * @param prettyPrint If true, the generated JSON will be well-formatted; otherwise, it will be compact.
     * @return The JSON string representation of the object, or null if the input object is null.
     * @throws AuraHandledException if a JSONException occurs during serialization.
     */
    public static String serialize(Object objToSerialize, Boolean prettyPrint) {
        if (objToSerialize == null) {
            return null; 
        }
        try {
            if (prettyPrint) {
                return JSON.serializePretty(objToSerialize);
            } else {
                return JSON.serialize(objToSerialize);
            }
        } catch (JSONException e) {
            System.debug(LoggingLevel.ERROR, 'JSON Serialization Error: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error serializing object to JSON. Details: ' + e.getMessage());
        }
    }

    /**
     * Deserializes a JSON string into an Apex object of the specified type.
     * @param jsonString The JSON string to deserialize.
     * @param targetType The target Apex Type to deserialize into.
     * @return The deserialized Apex object.
     * @throws AuraHandledException if jsonString or targetType is blank/null, or if a JSONException occurs.
     */
    public static Object deserialize(String jsonString, Type targetType) {
        if (String.isBlank(jsonString)) {
            throw new AuraHandledException('JSON string cannot be blank for deserialization.');
        }
        if (targetType == null) {
            throw new AuraHandledException('Target type cannot be null for deserialization.');
        }
        
        try {
            return JSON.deserialize(jsonString, targetType);
        } catch (JSONException e) {
            System.debug(LoggingLevel.ERROR, 'JSON Deserialization Error: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nJSON String (first 500 chars): ' + (jsonString.length() > 500 ? jsonString.substring(0, 500) : jsonString) );
            throw new AuraHandledException('Error deserializing JSON string to ' + targetType.getName() + '. Details: ' + e.getMessage());
        }
    }

    /**
     * Deserializes a JSON string (expected to be a JSON array) into a List of Apex objects of the specified item type.
     * @param jsonString The JSON string (array) to deserialize.
     * @param targetListItemType The target Apex Type for items within the list.
     * @return A List of deserialized Apex objects.
     * @throws AuraHandledException if jsonString or targetListItemType is blank/null, 
     *         if the List type cannot be constructed, or if a JSONException occurs.
     */
    public static List<Object> deserializeList(String jsonString, Type targetListItemType) {
        if (String.isBlank(jsonString)) {
            throw new AuraHandledException('JSON string cannot be blank for list deserialization.');
        }
        if (targetListItemType == null) {
            throw new AuraHandledException('Target list item type cannot be null for list deserialization.');
        }

        try {
            String listTypeName = 'List<' + targetListItemType.getName() + '>';
            Type listType = Type.forName(listTypeName);
            
            if (listType == null) {
                // This case might be rare if targetListItemType.getName() is valid, but Type.forName can return null.
                System.debug(LoggingLevel.ERROR, 'Could not construct List type for: ' + targetListItemType.getName() + '. Type.forName returned null for listTypeName: ' + listTypeName);
                throw new AuraHandledException('Could not construct List type for deserialization: ' + targetListItemType.getName());
            }
            return (List<Object>)JSON.deserialize(jsonString, listType);
        } catch (JSONException e) {
            System.debug(LoggingLevel.ERROR, 'JSON List Deserialization Error: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nJSON String (first 500 chars): ' + (jsonString.length() > 500 ? jsonString.substring(0, 500) : jsonString));
            throw new AuraHandledException('Error deserializing JSON string to List of ' + targetListItemType.getName() + '. Details: ' + e.getMessage());
        } catch (System.TypeException te) { // Catch errors from Type.forName specifically
            System.debug(LoggingLevel.ERROR, 'Type Error during JSON List Deserialization (Type.forName failed for "' + ('List<' + targetListItemType.getName() + '>') + '"): ' + te.getMessage() + '\nStack Trace: ' + te.getStackTraceString());
            throw new AuraHandledException('Could not form correct List type for deserialization of ' + targetListItemType.getName() + '. Ensure type name is correct. Details: ' + te.getMessage());
        }
    }
}
