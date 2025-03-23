public abstract inherited sharing class DMLService {
    public static final String ERROR_CREATE = 'Insuffienct permisson to create record(s).';

    @TestVisible
    private Schema.DescribeSObjectResult objectDescribe;

    public class DMLServiceException extends Exception { }

    @TestVisible
    public DMLService(SObjectType sObjectType) {
        objectDescribe = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public SObject create(SObject record) {
        if (!objectDescribe.isCreateable()) {
            throw new DMLServiceException(ERROR_CREATE);
        }

        insert record;
        return record;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual List<SObject> create(List<SObject> records) {
        if (!objectDescribe.isCreateable()) {
            throw new DMLServiceException(ERROR_CREATE);
        }

        insert records;
        return records;
    }
}