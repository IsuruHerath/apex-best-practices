@IsTest
private class AccountDMLServiceTest {
    @IsTest
    static void testGetInstance() {
        Test.startTest();
        AccountDMLService theFirstMostInstance = AccountDMLService.getInstance();
        AccountDMLService aSubsequenceInstance = AccountDMLService.getInstance();
        Test.stopTest();

        Assert.areEqual(theFirstMostInstance, aSubsequenceInstance, 'Should be same instance');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    static void testCreateRecord_withPermission() {
        Account accountRecord = TestUtil.generateAccount();

        Test.startTest();
        AccountDMLService.getInstance().create(accountRecord);
        Test.stopTest();

        Assert.isNotNull(accountRecord.Id, 'Should have an ID');
    }
}