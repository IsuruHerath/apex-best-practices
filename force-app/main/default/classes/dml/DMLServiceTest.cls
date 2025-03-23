@IsTest
private class DMLServiceTest {
    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    static void testCreateRecord_withPermission() {
        Account accountRecord = TestUtil.generateAccount();
        TestDMLService service = new TestDMLService();

        Test.startTest();
        service.create(accountRecord);
        Test.stopTest();

        Assert.isNotNull(accountRecord.Id, 'Should have an ID');
    }

    @IsTest
    @SuppressWarnings('PMD.MethodNamingConventions')
    static void testCreateRecords_withPermission() {
        List<Account> accountRecords = new List<Account>();
        accountRecords.add(TestUtil.generateAccount());
        TestDMLService service = new TestDMLService();

        Test.startTest();
        service.create(accountRecords);
        Test.stopTest();

        for(Account accountRecord : accountRecords) {
            Assert.isNotNull(accountRecord.Id, 'Should have an ID');
        }
    }

    class TestDMLService extends DMLService {
        public TestDMLService() {
            super(Schema.Account.SObjectType);
        }
    
        public Account create(Account record) {
            return (Account) super.create(record);
        }
    
        public List<Account> create(List<Account> records) {
            return (List<Account>) super.create(records);
        }
    }
}