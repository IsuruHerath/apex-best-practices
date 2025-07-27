@isTest
private class SOQLQueryBuilderTest {

    // --- Test Methods for Constructor and Basic Query ---
    @isTest
    static void testConstructor_ValidSObjectName() {
        Test.startTest();
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account');
        Test.stopTest();
        Assert.isNotNull(builder, 'Builder should not be null.');
        Assert.areEqual('SELECT Id FROM Account', builder.build(), 'Default query should select Id from Account.');
    }

    @isTest
    static void testConstructor_BlankSObjectName() {
        Exception caughtException = null;
        Test.startTest();
        try {
            new utilities.SOQLQueryBuilder('');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        Assert.isNotNull(caughtException, 'Exception should be thrown for blank sObjectName.');
        Assert.isTrue(caughtException instanceof utilities.SOQLQueryBuilder.IllegalArgumentException, 
                      'Expected IllegalArgumentException.');
        if(caughtException != null) { // Check for null before getMessage
             Assert.isTrue(caughtException.getMessage().contains('sObjectName cannot be blank'), 'Incorrect exception message.');
        }
    }

    // --- Test Methods for selectFields ---
    @isTest
    static void testSelectFields_Single() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Contact').selectField('LastName');
        Assert.areEqual('SELECT LastName FROM Contact', builder.build());
    }

    @isTest
    static void testSelectFields_Multiple() {
        List<String> fields = new List<String>{'FirstName', 'LastName', 'Email'};
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Contact').selectFields(fields);
        // Order might vary if Set is used internally for deduplication before join, but builder uses List.
        // The current builder adds fields in order, and new Set<String>(this.selectFields) in build() will sort.
        // For robust test, check for presence rather than exact string if order is not guaranteed.
        // For now, assuming alphabetical from Set conversion:
        Assert.areEqual('SELECT Email, FirstName, LastName FROM Contact', builder.build());
    }

    @isTest
    static void testSelectFields_EmptyList() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Opportunity').selectFields(new List<String>());
        Assert.areEqual('SELECT Id FROM Opportunity', builder.build(), 'Should default to SELECT Id for empty list.');
    }

    @isTest
    static void testSelectFields_NullList() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Case').selectFields(null);
        Assert.areEqual('SELECT Id FROM Case', builder.build(), 'Should default to SELECT Id for null list.');
    }

    @isTest
    static void testSelectField_Chaining() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Lead')
            .selectField('Company')
            .selectField('Status')
            .selectField('Company'); // Test deduplication in build()
        Assert.areEqual('SELECT Company, Status FROM Lead', builder.build());
    }
    
    // --- Test Methods for whereEquals ---
    @isTest
    static void testWhereEquals_StringValue() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account')
            .whereEquals('Name', 'Test Corp');
        Assert.areEqual('SELECT Id FROM Account WHERE Name = :bind0', builder.build());
    }

    @isTest
    static void testWhereEquals_IntegerValue() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Opportunity')
            .whereEquals('Amount', 10000);
        Assert.areEqual('SELECT Id FROM Opportunity WHERE Amount = :bind0', builder.build());
    }

    @isTest
    static void testWhereEquals_MultipleClauses() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Contact')
            .whereEquals('Department', 'Sales')
            .whereEquals('Level__c', 'Primary');
        Assert.areEqual('SELECT Id FROM Contact WHERE Department = :bind0 AND Level__c = :bind1', builder.build());
    }

    // --- Test Methods for whereIn ---
    @isTest
    static void testWhereIn_StringList() {
        List<String> types = new List<String>{'Prospect', 'Customer - Direct'};
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account')
            .whereIn('Type', types);
        Assert.areEqual('SELECT Id FROM Account WHERE Type IN :bind0', builder.build());
    }

    @isTest
    static void testWhereIn_IntegerList() {
        List<Integer> employeeCounts = new List<Integer>{100, 500, 1000};
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account')
            .whereIn('NumberOfEmployees', employeeCounts);
        Assert.areEqual('SELECT Id FROM Account WHERE NumberOfEmployees IN :bind0', builder.build());
    }

    // --- Test Methods for orderBy ---
    @isTest
    static void testOrderBy_Ascending() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Opportunity')
            .orderBy('CloseDate', 'ASC');
        Assert.areEqual('SELECT Id FROM Opportunity ORDER BY CloseDate ASC', builder.build());
    }

    @isTest
    static void testOrderBy_Descending() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Case')
            .orderBy('CreatedDate', 'DESC');
        Assert.areEqual('SELECT Id FROM Case ORDER BY CreatedDate DESC', builder.build());
    }

    @isTest
    static void testOrderBy_DefaultDirection() {
        utilities.SOQLQueryBuilder builder1 = new utilities.SOQLQueryBuilder('Lead').orderBy('LeadSource', null);
        Assert.areEqual('SELECT Id FROM Lead ORDER BY LeadSource ASC', builder1.build(), 'Null direction should default to ASC.');

        utilities.SOQLQueryBuilder builder2 = new utilities.SOQLQueryBuilder('Task').orderBy('Priority', 'INVALID_DIRECTION');
        Assert.areEqual('SELECT Id FROM Task ORDER BY Priority ASC', builder2.build(), 'Invalid direction should default to ASC.');
    }

    // --- Test Methods for limitResults ---
    @isTest
    static void testLimitResults_Valid() {
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account').limitResults(50);
        Assert.areEqual('SELECT Id FROM Account LIMIT 50', builder.build());
    }
    
    // --- Test Methods for build (Complex Combinations) ---
    @isTest
    static void testBuild_SelectWhereOrderByLimit() {
        List<String> fields = new List<String>{'Name', 'Industry', 'Type'};
        List<String> industries = new List<String>{'Technology', 'Finance'};
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account')
            .selectFields(fields)
            .whereEquals('Type', 'Customer')
            .whereIn('Industry', industries)
            .orderBy('Name', 'ASC')
            .limitResults(100);
        // SELECT fields are sorted by Set in build()
        String expectedQuery = 'SELECT Industry, Name, Type FROM Account WHERE Type = :bind0 AND Industry IN :bind1 ORDER BY Name ASC LIMIT 100';
        Assert.areEqual(expectedQuery, builder.build());
    }

    // --- Test Methods for execute ---
    @isTest
    static void testExecute_SimpleQuery() {
        String testAccountName = 'ExecuteTestAccount ' + System.currentTimeMillis();
        Account acc = new Account(Name = testAccountName, Industry = 'TestIndustry');
        insert acc;

        Test.startTest();
        utilities.SOQLQueryBuilder builder = new utilities.SOQLQueryBuilder('Account')
            .selectField('Name')
            .selectField('Industry')
            .whereEquals('Name', testAccountName)
            .whereEquals('Industry', 'TestIndustry');
        
        List<SObject> results = builder.execute();
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return one record.');
        Account queriedAccount = (Account)results[0];
        Assert.areEqual(testAccountName, queriedAccount.Name, 'Account name mismatch.');
        Assert.areEqual('TestIndustry', queriedAccount.Industry, 'Account industry mismatch.');
    }

    @isTest
    static void testExecute_QueryWithNoResults() {
        String nonExistentName = 'NonExistentName ' + System.currentTimeMillis();
        Test.startTest();
        List<SObject> results = new utilities.SOQLQueryBuilder('Account')
            .whereEquals('Name', nonExistentName)
            .execute();
        Test.stopTest();
        Assert.isTrue(results.isEmpty(), 'Should return an empty list for no results.');
    }

    @isTest
    static void testExecute_InvalidQuery_RuntimeError() {
        String testAccountName = 'ErrorTestAccount ' + System.currentTimeMillis();
        insert new Account(Name = testAccountName);

        Exception caughtException = null;
        Test.startTest();
        try {
            new utilities.SOQLQueryBuilder('Account')
                .selectField('NonExistentField__c') // This field does not exist
                .whereEquals('Name', testAccountName)
                .execute();
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        Assert.isNotNull(caughtException, 'QueryException should have been thrown.');
        // QueryException is wrapped in AuraHandledException by the service
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException.'); 
        if(caughtException != null) {
            Assert.isTrue(caughtException.getMessage().contains('No such column \'NonExistentField__c\'') || 
                          caughtException.getMessage().contains('query execution failed'), // General message
                          'Exception message should indicate an issue with the field. Actual: ' + caughtException.getMessage());
        }
    }
}
