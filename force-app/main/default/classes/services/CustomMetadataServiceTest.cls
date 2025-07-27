@isTest
private class CustomMetadataServiceTest {

    @isTest
    static void testGetAllRecords_BlankApiName() {
        Exception caughtException = null; // Initialize to null
        Test.startTest();
        try {
            CustomMetadataService.getAllRecords('');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'An exception should have been thrown for blank API name.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException for blank API name.');
        if (caughtException != null) { // Check to prevent null pointer on getMessage()
            Assert.isTrue(caughtException.getMessage().contains('API Name cannot be blank'), 
                          'Unexpected exception message: ' + caughtException.getMessage());
        }
    }

    @isTest
    static void testGetAllRecords_InvalidApiName() {
        Exception caughtException = null; // Initialize to null
        String invalidApiName = 'Non_Existent_CMDT__mdt_ABC123'; // Make it unique
        Test.startTest();
        try {
            CustomMetadataService.getAllRecords(invalidApiName);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'An exception should have been thrown for invalid API name.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException for invalid API name.');
        if (caughtException != null) {
            // The service throws 'Error fetching records for...' which wraps schema describe errors or query errors.
            Assert.isTrue(caughtException.getMessage().contains('Error fetching records for ' + invalidApiName), 
                          'Exception message should indicate an issue with the API name ' + invalidApiName + 
                          '. Actual: ' + caughtException.getMessage());
        }
    }

    @isTest
    static void testGetRecord_BlankApiName() {
        Exception caughtException = null; // Initialize to null
        Test.startTest();
        try {
            CustomMetadataService.getRecord('', 'SomeDeveloperName');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'An exception should have been thrown for blank API name.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException.');
        if (caughtException != null) {
            Assert.isTrue(caughtException.getMessage().contains('API Name and Developer Name cannot be blank'),
                          'Unexpected exception message: ' + caughtException.getMessage());
        }
    }

    @isTest
    static void testGetRecord_BlankDeveloperName() {
        Exception caughtException = null; // Initialize to null
        String validLookingApiName = 'My_Test_CMDT__mdt'; // A plausible API name format
        Test.startTest();
        try {
            CustomMetadataService.getRecord(validLookingApiName, '');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'An exception should have been thrown for blank DeveloperName.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException.');
        if (caughtException != null) {
            Assert.isTrue(caughtException.getMessage().contains('API Name and Developer Name cannot be blank'),
                          'Unexpected exception message: ' + caughtException.getMessage());
        }
    }

    @isTest
    static void testGetRecord_InvalidApiName() {
        Exception caughtException = null; // Initialize to null
        String invalidApiName = 'Non_Existent_CMDT__mdt_XYZ789'; // Make it unique
        String developerName = 'SomeDeveloperName';
        Test.startTest();
        try {
            CustomMetadataService.getRecord(invalidApiName, developerName);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'An exception should have been thrown for invalid API name.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException for invalid API name.');
        if (caughtException != null) {
            // The service throws 'Error fetching record...' which wraps schema describe errors or query errors.
            Assert.isTrue(caughtException.getMessage().contains('Error fetching record ' + developerName + ' for ' + invalidApiName), 
                          'Exception message should indicate an issue with the API name ' + invalidApiName + 
                          '. Actual: ' + caughtException.getMessage());
        }
    }

    // testGetRecord_RecordNotFound is intentionally omitted as per task instructions,
    // acknowledging the difficulty in testing this without a deployed CMDT.
}
