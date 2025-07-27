@isTest
private class DescribeServiceTest {

    // Helper to ensure clean cache before each test method
    @TestSetup
    static void setup() {
        DescribeService.clearCache();
    }
    
    private static void expectAuraHandledException(String methodName, String sObjectName, String fieldName, String expectedMessagePart) {
        Exception caughtException = null;
        Test.startTest();
        try {
            if (methodName == 'getSObjectDescribe') DescribeService.getSObjectDescribe(sObjectName);
            else if (methodName == 'getFieldDescribe') DescribeService.getFieldDescribe(sObjectName, fieldName);
            else if (methodName == 'getPicklistValues') DescribeService.getPicklistValues(sObjectName, fieldName);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        Assert.isNotNull(caughtException, 'Expected AuraHandledException for ' + methodName + ' with sObject: ' + sObjectName + ', field: ' + fieldName);
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException type for ' + methodName);
        if (caughtException != null && expectedMessagePart != null) {
            Assert.isTrue(caughtException.getMessage().contains(expectedMessagePart), 
                          'Unexpected exception message for ' + methodName + '. Expected: "' + expectedMessagePart + 
                          '". Actual: "' + caughtException.getMessage() + '"');
        }
    }

    // --- Test Methods for getSObjectDescribe ---
    @isTest
    static void testGetSObjectDescribe_Valid() {
        DescribeService.clearCache(); // Ensure clean state for this specific test
        Test.startTest();
        Schema.DescribeSObjectResult result = DescribeService.getSObjectDescribe('Account');
        Test.stopTest();
        Assert.isNotNull(result, 'DescribeSObjectResult should not be null for Account.');
        Assert.areEqual('Account', result.getName(), 'SObject name should be Account.');
    }

    @isTest static void testGetSObjectDescribe_Invalid() { expectAuraHandledException('getSObjectDescribe', 'NonExistentObject__c_XYZ', null, 'SObject type \'NonExistentObject__c_XYZ\' not found');}
    @isTest static void testGetSObjectDescribe_Blank_Null() { expectAuraHandledException('getSObjectDescribe', null, null, 'sObject Name cannot be blank');}
    @isTest static void testGetSObjectDescribe_Blank_Empty() { expectAuraHandledException('getSObjectDescribe', '', null, 'sObject Name cannot be blank');}

    @isTest
    static void testGetSObjectDescribe_Caching() {
        DescribeService.clearCache();
        // Initial call to populate cache
        DescribeService.getSObjectDescribe('Account');
        
        Test.startTest();
        Integer baselineDescribes = Limits.getDescribeSObjects();
        DescribeService.getSObjectDescribe('Account'); // Should hit cache
        Integer afterFirstCachedCall = Limits.getDescribeSObjects();
        Assert.areEqual(baselineDescribes, afterFirstCachedCall, 'DescribeSObjects count should not increase for cached "Account" describe.');

        DescribeService.getSObjectDescribe('Contact'); // New SObject, should miss cache
        Integer afterSecondNewCall = Limits.getDescribeSObjects();
        Test.stopTest();
        Assert.areEqual(baselineDescribes + 1, afterSecondNewCall, 'DescribeSObjects count should increase by 1 for new "Contact" describe.');
    }

    // --- Test Methods for getFieldDescribe ---
    @isTest
    static void testGetFieldDescribe_Valid() {
        DescribeService.clearCache();
        Test.startTest();
        Schema.DescribeFieldResult result = DescribeService.getFieldDescribe('Account', 'Name');
        Test.stopTest();
        Assert.isNotNull(result, 'DescribeFieldResult should not be null for Account.Name.');
        Assert.areEqual('Name', result.getName(), 'Field name should be Name.');
    }

    @isTest static void testGetFieldDescribe_InvalidSObject() { expectAuraHandledException('getFieldDescribe', 'NonExistentObject__c_ABC', 'Name', 'SObject type \'NonExistentObject__c_ABC\' not found');}
    @isTest static void testGetFieldDescribe_InvalidField() { expectAuraHandledException('getFieldDescribe', 'Account', 'NonExistentField__c_DEF', 'Field \'NonExistentField__c_DEF\' not found');}
    @isTest static void testGetFieldDescribe_BlankSObject() { expectAuraHandledException('getFieldDescribe', '', 'Name', 'sObject Name and Field Name cannot be blank');}
    @isTest static void testGetFieldDescribe_BlankField() { expectAuraHandledException('getFieldDescribe', 'Account', null, 'sObject Name and Field Name cannot be blank');}

    @isTest
    static void testGetFieldDescribe_Caching() {
        DescribeService.clearCache();
        // Populate caches
        DescribeService.getFieldDescribe('Account', 'Name'); // sObject and field cache
        DescribeService.getSObjectDescribe('Contact'); // sObject cache for Contact

        Test.startTest();
        Integer baselineFieldDescribes = Limits.getDescribeFields();
        Integer baselineSObjectDescribes = Limits.getDescribeSObjects();

        DescribeService.getFieldDescribe('Account', 'Name'); // Should hit field cache
        Assert.areEqual(baselineFieldDescribes, Limits.getDescribeFields(), 'DescribeFields count should not increase for cached "Account.Name".');
        
        DescribeService.getFieldDescribe('Account', 'Industry'); // sObject cache hit, field cache miss
        Assert.areEqual(baselineFieldDescribes + 1, Limits.getDescribeFields(), 'DescribeFields count should increase by 1 for "Account.Industry".');
        
        DescribeService.getFieldDescribe('Contact', 'Email'); // sObject cache hit (from setup), field cache miss
        Assert.areEqual(baselineFieldDescribes + 2, Limits.getDescribeFields(), 'DescribeFields count should increase again for "Contact.Email".');
        
        // SObject describes should not have increased beyond initial cache populations if done correctly.
        Assert.areEqual(baselineSObjectDescribes, Limits.getDescribeSObjects(), 'DescribeSObjects count should remain stable if sObjects already cached.');
        Test.stopTest();
    }

    // --- Test Methods for getPicklistValues ---
    @isTest
    static void testGetPicklistValues_Valid() {
        DescribeService.clearCache();
        Test.startTest();
        List<Schema.PicklistEntry> values = DescribeService.getPicklistValues('Account', 'Industry');
        Test.stopTest();
        Assert.isNotNull(values, 'Picklist values list should not be null for Account.Industry.');
        Assert.isFalse(values.isEmpty(), 'Account.Industry should have picklist values.');
    }

    @isTest static void testGetPicklistValues_NotPicklistField() { expectAuraHandledException('getPicklistValues', 'Account', 'Name', 'is not a picklist or multipicklist field');}
    @isTest static void testGetPicklistValues_InvalidSObject() { expectAuraHandledException('getPicklistValues', 'NonExistentObject__c_GHI', 'SomeField__c', 'SObject type \'NonExistentObject__c_GHI\' not found');}
    @isTest static void testGetPicklistValues_InvalidField() { expectAuraHandledException('getPicklistValues', 'Account', 'NonExistentPicklist__c_JKL', 'Field \'NonExistentPicklist__c_JKL\' not found');}
    @isTest static void testGetPicklistValues_BlankSObject() { expectAuraHandledException('getPicklistValues', '', 'Industry', 'sObject Name and Field Name cannot be blank');}
    @isTest static void testGetPicklistValues_BlankField() { expectAuraHandledException('getPicklistValues', 'Account', null, 'sObject Name and Field Name cannot be blank');}

    @isTest
    static void testGetPicklistValues_Caching() {
        DescribeService.clearCache();
        // Populate caches
        DescribeService.getPicklistValues('Account', 'Industry'); // Populates sObject, field, and picklist caches for Account.Industry
        
        Test.startTest();
        // Limits.getDescribePicklistValues() is not a method. Caching relies on DescribeFieldResult cache.
        // We test if underlying field describe calls are cached.
        Integer baselineFieldDescribes = Limits.getDescribeFields();

        DescribeService.getPicklistValues('Account', 'Industry'); // Should hit picklist cache (and field cache)
        Assert.areEqual(baselineFieldDescribes, Limits.getDescribeFields(), 'DescribeFields count should not increase for cached picklist "Account.Industry".');

        // Assuming 'AccountShare' does not have a picklist field 'Type' standardly, or if it does, test a different one.
        // Let's test with another picklist field on Account to see if field describe increases.
        // 'AccountSource' is another standard picklist on Account.
        DescribeService.getPicklistValues('Account', 'AccountSource'); // sObject cache hit, field & picklist cache miss
        Assert.areEqual(baselineFieldDescribes + 1, Limits.getDescribeFields(), 'DescribeFields count should increase for new picklist "Account.AccountSource".');
        Test.stopTest();
    }
}
