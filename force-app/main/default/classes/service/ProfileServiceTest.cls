@isTest
private class ProfileServiceTest {

    private static final String STANDARD_USER_PROFILE_NAME = 'Standard User';
    private static Id standardUserProfileId;
    private static Profile standardUserProfileSObject; // Renamed for clarity

    @TestSetup
    static void setup() {
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = :STANDARD_USER_PROFILE_NAME LIMIT 1];
        if (!profiles.isEmpty()) {
            standardUserProfileSObject = profiles[0];
            standardUserProfileId = standardUserProfileSObject.Id;
        } else {
            System.debug(LoggingLevel.WARN, STANDARD_USER_PROFILE_NAME + ' profile not found. Tests may be affected.');
        }
        // Ensure cache is clear before any test method might trigger initialization
        ProfileService.clearCache();
    }

    // Helper to call the @TestVisible clearCache method in ProfileService
    private static void clearServiceCache() {
        ProfileService.clearCache(); // This ensures isCacheInitialized is false
    }

    @isTest
    static void testGetValidProfileId() {
        clearServiceCache(); 
        Assert.isNotNull(standardUserProfileId, 'Test setup error: ' + STANDARD_USER_PROFILE_NAME + ' ID not found.');

        Test.startTest();
        // First call to ProfileService.getInstance() or any static method initializes the cache
        Id actualId = ProfileService.getProfileId(STANDARD_USER_PROFILE_NAME);
        Test.stopTest();

        Assert.areEqual(standardUserProfileId, actualId, 'Should return correct ID for ' + STANDARD_USER_PROFILE_NAME);
    }

    @isTest
    static void testGetNonExistentProfileId() {
        clearServiceCache();
        String nonExistentProfileName = 'This Profile Really Does Not Exist ' + Math.random();

        Test.startTest();
        Id actualId = ProfileService.getProfileId(nonExistentProfileName);
        Test.stopTest();

        Assert.isNull(actualId, 'Should return null for a non-existent Profile name (ID check).');
    }

    @isTest
    static void testProfileIdCaseInsensitivity() {
        clearServiceCache();
        Assert.isNotNull(standardUserProfileId, 'Test setup error: ' + STANDARD_USER_PROFILE_NAME + ' ID not found.');

        String profileNameUpper = STANDARD_USER_PROFILE_NAME.toUpperCase();
        String profileNameLower = STANDARD_USER_PROFILE_NAME.toLowerCase();
        
        Test.startTest();
        // Cache initializes on first access
        Id idFromOriginal = ProfileService.getProfileId(STANDARD_USER_PROFILE_NAME);
        Id idFromUpper = ProfileService.getProfileId(profileNameUpper);
        Id idFromLower = ProfileService.getProfileId(profileNameLower);
        Test.stopTest();

        Assert.areEqual(standardUserProfileId, idFromOriginal, 'ID from original case mismatch.');
        Assert.areEqual(standardUserProfileId, idFromUpper, 'ID from upper case mismatch.');
        Assert.areEqual(standardUserProfileId, idFromLower, 'ID from lower case mismatch.');
    }

    @isTest
    static void testGetValidProfileSObject() {
        clearServiceCache();
        Assert.isNotNull(standardUserProfileSObject, 'Test setup error: ' + STANDARD_USER_PROFILE_NAME + ' sObject not found.');

        Test.startTest();
        Profile actualProfile = ProfileService.getProfile(STANDARD_USER_PROFILE_NAME);
        Test.stopTest();

        Assert.isNotNull(actualProfile, 'Profile sObject should not be null.');
        Assert.areEqual(standardUserProfileId, actualProfile.Id, 'Profile sObject ID mismatch.');
        Assert.areEqual(standardUserProfileSObject.Name, actualProfile.Name, 'Profile sObject Name mismatch.');
    }

    @isTest
    static void testGetNonExistentProfileSObject() {
        clearServiceCache();
        String nonExistentProfileName = 'This Profile Really Does Not Exist SObject ' + Math.random();
        Test.startTest();
        Profile actualProfile = ProfileService.getProfile(nonExistentProfileName);
        Test.stopTest();
        Assert.isNull(actualProfile, 'Should return null for non-existent Profile name (sObject check).');
    }

    @isTest
    static void testProfileSObjectCaseInsensitivity() {
        clearServiceCache();
        Assert.isNotNull(standardUserProfileSObject, 'Test setup error: ' + STANDARD_USER_PROFILE_NAME + ' sObject not found.');

        String profileNameUpper = STANDARD_USER_PROFILE_NAME.toUpperCase();
        String profileNameLower = STANDARD_USER_PROFILE_NAME.toLowerCase();

        Test.startTest();
        Profile profileFromOriginal = ProfileService.getProfile(STANDARD_USER_PROFILE_NAME);
        Profile profileFromUpper = ProfileService.getProfile(profileNameUpper);
        Profile profileFromLower = ProfileService.getProfile(profileNameLower);
        Test.stopTest();

        Assert.isNotNull(profileFromOriginal, 'Profile from original case should not be null.');
        Assert.areEqual(standardUserProfileId, profileFromOriginal.Id, 'Original case: Profile sObject ID mismatch.');
        
        Assert.isNotNull(profileFromUpper, 'Profile from upper case should not be null.');
        Assert.areEqual(standardUserProfileId, profileFromUpper.Id, 'Upper case: Profile sObject ID mismatch.');

        Assert.isNotNull(profileFromLower, 'Profile from lower case should not be null.');
        Assert.areEqual(standardUserProfileId, profileFromLower.Id, 'Lower case: Profile sObject ID mismatch.');
    }

    @isTest
    static void testGetAllProfiles() {
        clearServiceCache();
        Test.startTest();
        Map<String, Profile> allProfilesMap = ProfileService.getAllProfiles();
        Test.stopTest();

        Assert.isNotNull(allProfilesMap, 'getAllProfiles() should not return null.');
        Assert.isFalse(allProfilesMap.isEmpty(), 'Profile map should not be empty in a typical org.');
        
        // Assuming a typical org has at least a few standard profiles (e.g., Standard User, System Administrator)
        Assert.isTrue(allProfilesMap.size() > 1, 'Profile map should contain several profiles.'); 

        String lowerCaseProfileName = STANDARD_USER_PROFILE_NAME.toLowerCase();
        Assert.isTrue(allProfilesMap.containsKey(lowerCaseProfileName), 'Map should contain key: ' + lowerCaseProfileName);
        Assert.isNotNull(allProfilesMap.get(lowerCaseProfileName), STANDARD_USER_PROFILE_NAME + ' profile should exist in map.');
        if (standardUserProfileId != null) {
            Assert.areEqual(standardUserProfileId, allProfilesMap.get(lowerCaseProfileName).Id, STANDARD_USER_PROFILE_NAME + ' ID in map mismatch.');
        }
    }

    @isTest
    static void testCacheInitialization() {
        clearServiceCache(); // Ensures isCacheInitialized = false

        // Capture SOQL before any service call
        Integer queriesBefore = Limits.getQueries();

        Test.startTest();
        // This call will trigger static block and initializeCache()
        Map<String, Profile> profiles = ProfileService.getAllProfiles(); 
        Test.stopTest();

        Integer queriesAfter = Limits.getQueries();

        Assert.isFalse(profiles.isEmpty(), 'Profiles map should be populated after initialization.');
        Assert.isTrue(queriesAfter > queriesBefore, 'SOQL queries should have been made for cache initialization.');
        
        // Subsequent call should not increase SOQL queries
        Integer queriesBeforeSecondCall = Limits.getQueries();
        ProfileService.getProfileId(STANDARD_USER_PROFILE_NAME); // Example call
        Integer queriesAfterSecondCall = Limits.getQueries();
        Assert.areEqual(queriesBeforeSecondCall, queriesAfterSecondCall, 'Subsequent calls should not cause more SOQL queries.');
    }
    
    @isTest
    static void testGetProfileIdWithNullName() {
        clearServiceCache();
        Test.startTest();
        Id actualId = ProfileService.getProfileId(null);
        Test.stopTest();
        Assert.isNull(actualId, 'getProfileId(null) should return null.');
    }

    @isTest
    static void testGetProfileSObjectWithNullName() {
        clearServiceCache();
        Test.startTest();
        Profile actualProfile = ProfileService.getProfile(null);
        Test.stopTest();
        Assert.isNull(actualProfile, 'getProfile(null) should return null.');
    }
}
