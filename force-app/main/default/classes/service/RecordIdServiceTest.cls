@IsTest
private class RecordIdServiceTest {
    @IsTest
    static void testRecordIdService() {
        Test.startTest();
        Id thefirstAccountId = RecordIdService.getInstance().generateNextId(Schema.Account.SObjectType);
        Id thenextAccountId = RecordIdService.getInstance().generateNextId(Schema.Account.SObjectType);
        Test.stopTest();

        Assert.areNotEqual(thefirstAccountId, thenextAccountId, 'Should be different Ids');
    }
}