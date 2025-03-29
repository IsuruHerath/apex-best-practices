@IsTest
private class AccountBuilderTest {
    @IsTest
    static void testAccountBuilder() {
        Id accountId = RecordIdService.getInstance().generateNextId(Schema.Account.SObjectType);
        String name = 'Test Account';

        Test.startTest();
        Account accountRecord = AccountBuilder.getBuilder()
            .setId(accountId)
            .setName(name)
            .build();
        Test.stopTest();

        Assert.areEqual(accountId, accountRecord.Id, 'Should have the same Id');
        Assert.areEqual(name, accountRecord.Name, 'Should have the same name');
    }
}