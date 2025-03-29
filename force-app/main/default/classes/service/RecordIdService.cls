public with sharing class RecordIdService {
    private static RecordIdService service;
    private final Map<Schema.SObjectType, Integer> countBySObjectType;

    private RecordIdService() {
        countBySObjectType = new Map<Schema.SObjectType, Integer>();
    }

    public static RecordIdService getInstance() {
        if(service == null) {
            service = new RecordIdService();
        }

        return service;
    }

    public Id generateNextId(Schema.SObjectType type) {
        if(!countBySObjectType.containsKey(type)) {
            countBySObjectType.put(type, 0);
        }

        Integer nextSequenceNumber = countBySObjectType.get(type) + 1;
        countBySObjectType.put(type, nextSequenceNumber);
        
        return generateId(type, nextSequenceNumber);
    }

    public Id generateId(Schema.SObjectType type, Integer sequenceNumber) {
        String sequenceInStringFormat = String.valueOf(sequenceNumber);
        String objectPrefix = type.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix();
        String idSequence = '0'.repeat(12-sequenceInStringFormat.length()) + sequenceInStringFormat;

        return String.format('{0}{1}', new List<String> { objectPrefix, idSequence });
    }
}