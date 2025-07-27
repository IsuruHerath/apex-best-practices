@isTest
private class CustomSettingsServiceTest {

    @isTest
    static void testGetAllSettings_BlankApiName() {
        Map<String, SObject> result;
        Exception actualException; // To catch expected exceptions for assertion
        
        // The service's current implementation for blank API name in getAllSettings returns an empty map, not an exception.
        // Let's adjust the test to expect an empty map. If it were to throw, we'd use a try-catch.
        
        Test.startTest();
        result = CustomSettingsService.getAllSettings('');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null for blank API name.');
        Assert.isTrue(result.isEmpty(), 'Result should be empty for blank API name.');
        Assert.isNull(actualException, 'No exception should be thrown for blank API name if service returns empty map.');
    }

    @isTest
    static void testGetAllSettings_InvalidApiName() {
        Exception actualException = null;
        Test.startTest();
        try {
            // Using a clearly invalid and non-existent SObject API name.
            CustomSettingsService.getAllSettings('NonExistent_Setting__c_12345');
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        Assert.isNotNull(actualException, 'An exception should have been thrown for an invalid API name.');
        Assert.isTrue(actualException instanceof AuraHandledException, 'Expected AuraHandledException for invalid API name.');
        // Check if the message indicates that the SObject type was not found or there was a describe error.
        // The exact message comes from the service: 'Error describing custom setting SObject: ...'
        Assert.isTrue(actualException.getMessage().contains('Error describing custom setting SObject'), 
                      'Exception message should indicate an error describing the SObject type.');
    }

    @isTest
    static void testGetSetting_BlankApiName() {
        SObject result;
        Exception actualException = null;
        // The service's current implementation for blank API name in getSetting returns null.
        Test.startTest();
        result = CustomSettingsService.getSetting('', 'TestSetting');
        Test.stopTest();
        
        Assert.isNull(result, 'Result should be null for blank API name.');
        Assert.isNull(actualException, 'No exception should be thrown for blank API name if service returns null.');
    }

    @isTest
    static void testGetSetting_BlankSettingName() {
        SObject result;
        Exception actualException = null;
        // The service's current implementation for blank setting name in getSetting returns null.
        Test.startTest();
        // Provide a valid-looking (but not necessarily existing) API name for the custom setting
        result = CustomSettingsService.getSetting('My_Possible_Setting__c', '');
        Test.stopTest();

        Assert.isNull(result, 'Result should be null for blank setting name.');
        Assert.isNull(actualException, 'No exception should be thrown for blank setting name if service returns null.');
    }

    @isTest
    static void testGetSetting_InvalidApiName() {
        Exception actualException = null;
        Test.startTest();
        try {
            // Using a clearly invalid and non-existent SObject API name.
            CustomSettingsService.getSetting('NonExistent_Setting__c_67890', 'TestName');
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        Assert.isNotNull(actualException, 'An exception should have been thrown for an invalid API name.');
        Assert.isTrue(actualException instanceof AuraHandledException, 'Expected AuraHandledException for invalid API name.');
        Assert.isTrue(actualException.getMessage().contains('Error describing custom setting SObject'), 
                      'Exception message should indicate an error describing the SObject type.');
    }

    // As per instructions, testGetSetting_SettingNotFound is skipped due to limitations.
    // testGetInstance is also skipped as the class has a private constructor and only static methods.
}
