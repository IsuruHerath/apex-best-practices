@isTest
private class JSONSerializerServiceTest {

    // Inner class for testing custom object serialization/deserialization
    private class TestObject {
        public String name;
        public Integer value;
        public Boolean isActive;

        public TestObject(String n, Integer v, Boolean active) {
            this.name = n;
            this.value = v;
            this.isActive = active;
        }

        public Boolean equals(Object obj) {
            if (obj == null || !(obj instanceof TestObject)) {
                return false;
            }
            TestObject that = (TestObject) obj;
            return this.name == that.name && this.value == that.value && this.isActive == that.isActive;
        }
        
        // hashCode is good practice to override when equals is overridden, though not strictly required by Apex assertions.
        public Integer hashCode() {
            return System.hashCode(this.name) ^ System.hashCode(this.value) ^ System.hashCode(this.isActive);
        }
    }

    // --- Test Methods for serialize ---

    @isTest
    static void testSerialize_NullObject() {
        Test.startTest();
        String jsonOutput = JSONSerializerService.serialize(null, false);
        Test.stopTest();
        Assert.isNull(jsonOutput, 'Serializing a null object should result in null.');
    }

    @isTest
    static void testSerialize_SimpleObject_NoPrettyPrint() {
        TestObject obj = new TestObject('Test1', 100, true);
        Test.startTest();
        String jsonOutput = JSONSerializerService.serialize(obj, false);
        Test.stopTest();
        // Expected: {"name":"Test1","value":100,"isActive":true} or similar compact form
        Assert.isNotNull(jsonOutput, 'JSON output should not be null.');
        Assert.isTrue(jsonOutput.contains('"name":"Test1"'), 'JSON should contain name field.');
        Assert.isTrue(jsonOutput.contains('"value":100'), 'JSON should contain value field.');
        Assert.isTrue(jsonOutput.contains('"isActive":true'), 'JSON should contain isActive field.');
        Assert.isFalse(jsonOutput.contains('\n'), 'JSON should be compact (no newlines).');
    }

    @isTest
    static void testSerialize_SimpleObject_PrettyPrint() {
        TestObject obj = new TestObject('Test2', 200, false);
        Test.startTest();
        String jsonOutput = JSONSerializerService.serialize(obj, true);
        Test.stopTest();
        Assert.isNotNull(jsonOutput, 'JSON output should not be null.');
        Assert.isTrue(jsonOutput.contains('"name" : "Test2"'), 'Pretty JSON should contain name field.'); // Note space for pretty
        Assert.isTrue(jsonOutput.contains('\n'), 'Pretty JSON should contain newlines.');
    }

    @isTest
    static void testSerialize_SObject() {
        Account acc = new Account(Name = 'SObject Test', AccountNumber = '12345');
        // Note: Only fields explicitly set or queried are typically serialized for SObjects.
        // If you want to test specific fields, ensure they are populated.
        Test.startTest();
        String jsonOutput = JSONSerializerService.serialize(acc, false);
        Test.stopTest();
        Assert.isNotNull(jsonOutput, 'JSON output for SObject should not be null.');
        Assert.isTrue(jsonOutput.contains('"Name":"SObject Test"'), 'JSON should contain SObject Name.');
        Assert.isTrue(jsonOutput.contains('"AccountNumber":"12345"'), 'JSON should contain AccountNumber.');
    }

    @isTest
    static void testSerialize_List() {
        List<String> stringList = new List<String>{'apple', 'banana'};
        Test.startTest();
        String jsonOutput = JSONSerializerService.serialize(stringList, false);
        Test.stopTest();
        Assert.toEqual('["apple","banana"]', jsonOutput, 'Serialized list of strings is incorrect.');

        List<Integer> intList = new List<Integer>{1, 2, 3};
        Test.startTest();
        jsonOutput = JSONSerializerService.serialize(intList, false);
        Test.stopTest();
        Assert.toEqual('[1,2,3]', jsonOutput, 'Serialized list of integers is incorrect.');
    }

    // --- Test Methods for deserialize ---

    private static void expectAuraHandledException(String methodName, String jsonString, Type targetType, String expectedMessagePart) {
        Exception caughtException = null;
        Test.startTest();
        try {
            if (methodName == 'deserialize') JSONSerializerService.deserialize(jsonString, targetType);
            else if (methodName == 'deserializeList') JSONSerializerService.deserializeList(jsonString, targetType);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        Assert.isNotNull(caughtException, 'Expected AuraHandledException for ' + methodName + ' with message part: ' + expectedMessagePart);
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException type for ' + methodName);
        if (caughtException != null && expectedMessagePart != null) {
            Assert.isTrue(caughtException.getMessage().contains(expectedMessagePart), 
                          'Unexpected exception message for ' + methodName + '. Expected to contain: "' + expectedMessagePart + 
                          '". Actual: "' + caughtException.getMessage() + '"');
        }
    }

    @isTest static void testDeserialize_NullString() { expectAuraHandledException('deserialize', null, String.class, 'JSON string cannot be blank'); }
    @isTest static void testDeserialize_BlankString() { expectAuraHandledException('deserialize', '', String.class, 'JSON string cannot be blank'); }
    @isTest static void testDeserialize_NullType() { expectAuraHandledException('deserialize', '{}', null, 'Target type cannot be null'); }
    
    @isTest
    static void testDeserialize_SimpleObject() {
        String jsonInput = '{"name":"DeserializeTest","value":50,"isActive":true}';
        Test.startTest();
        TestObject deserializedObj = (TestObject)JSONSerializerService.deserialize(jsonInput, TestObject.class);
        Test.stopTest();
        Assert.isNotNull(deserializedObj, 'Deserialized object should not be null.');
        TestObject expectedObj = new TestObject('DeserializeTest', 50, true);
        Assert.isTrue(expectedObj.equals(deserializedObj), 'Deserialized object properties do not match.');
    }

    @isTest
    static void testDeserialize_SObject() {
        String jsonInput = '{"attributes":{"type":"Account"},"Name":"SObject Deserialize","Industry":"Tech"}';
        Test.startTest();
        Account acc = (Account)JSONSerializerService.deserialize(jsonInput, Account.class);
        Test.stopTest();
        Assert.isNotNull(acc, 'Deserialized Account should not be null.');
        Assert.toEqual('SObject Deserialize', acc.Name, 'Account Name mismatch.');
        Assert.toEqual('Tech', acc.Industry, 'Account Industry mismatch.');
    }

    @isTest static void testDeserialize_InvalidJson() { expectAuraHandledException('deserialize', 'invalid json string', String.class, 'Error deserializing JSON string'); }
    @isTest static void testDeserialize_TypeMismatch() { expectAuraHandledException('deserialize', '{"name":"Mismatch"}', Integer.class, 'Error deserializing JSON string'); }

    // --- Test Methods for deserializeList ---

    @isTest static void testDeserializeList_NullString() { expectAuraHandledException('deserializeList', null, String.class, 'JSON string cannot be blank'); }
    @isTest static void testDeserializeList_BlankString() { expectAuraHandledException('deserializeList', '', String.class, 'JSON string cannot be blank'); }
    @isTest static void testDeserializeList_NullType() { expectAuraHandledException('deserializeList', '[]', null, 'Target list item type cannot be null'); }

    @isTest
    static void testDeserializeList_SimpleList() {
        String jsonInput = '["value1","value2","value3"]';
        Test.startTest();
        List<Object> deserializedList = JSONSerializerService.deserializeList(jsonInput, String.class);
        Test.stopTest();
        Assert.isNotNull(deserializedList, 'Deserialized list should not be null.');
        Assert.areEqual(3, deserializedList.size(), 'List size mismatch.');
        Assert.isTrue(deserializedList[0] instanceof String, 'List item type mismatch.');
        Assert.toEqual('value1', (String)deserializedList[0]);
        Assert.toEqual('value2', (String)deserializedList[1]);
    }

    @isTest
    static void testDeserializeList_ListOfObjects() {
        String jsonInput = '[{"name":"Obj1","value":10,"isActive":true},{"name":"Obj2","value":20,"isActive":false}]';
        Test.startTest();
        List<Object> deserializedList = JSONSerializerService.deserializeList(jsonInput, TestObject.class);
        Test.stopTest();
        Assert.isNotNull(deserializedList, 'Deserialized list of objects should not be null.');
        Assert.areEqual(2, deserializedList.size(), 'List of objects size mismatch.');
        Assert.isTrue(deserializedList[0] instanceof TestObject, 'List item type should be TestObject.');
        
        TestObject expectedObj1 = new TestObject('Obj1', 10, true);
        Assert.isTrue(expectedObj1.equals(deserializedList[0]), 'First deserialized object mismatch.');
    }
    
    @isTest static void testDeserializeList_InvalidJsonArray() { expectAuraHandledException('deserializeList', '[{"name":Test" invalid}]', TestObject.class, 'Error deserializing JSON string to List'); }
    @isTest static void testDeserializeList_JsonNotArray() { expectAuraHandledException('deserializeList', '{"name":"NotAnArray"}', TestObject.class, 'Error deserializing JSON string to List'); }
    
    // testDeserializeList_TypeForNameFails is harder to reliably trigger without specific non-standard type names.
    // If targetListItemType.getName() returns something Type.forName doesn't like (e.g. includes generics itself, or is primitive like 'Integer' instead of 'System.Integer')
    // it would fail. The service uses targetListItemType.getName(), which for system types like String.class or custom classes like TestObject.class, should be valid.
    // Primitives might cause issues if not handled carefully by Type.forName in list context; however, Apex typically handles this.
    // For now, this specific edge case is considered covered by the existing TypeException catch in the service if it were to occur.
}
