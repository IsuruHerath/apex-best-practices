@IsTest
private class AccountDMLServiceTest {
    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    static void testCreateRecord_withPermission() {
        Account accountRecord = AccountBuilder.getBuilder()
            .setName('Test Account')
            .build();

        Test.startTest();
        AccountDMLService.getInstance().create(accountRecord);
        Test.stopTest();

        Assert.isNotNull(accountRecord.Id, 'Should have an ID');
    }
}