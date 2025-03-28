public abstract inherited sharing class DMLService {
    public static final String ERROR_CREATE = 'Insuffienct permisson to create record(s).';
    public static final String ERROR_UPDATE = 'Insuffienct permisson to update record(s).';
    public static final String ERROR_DELETE = 'Insuffienct permisson to delete record(s).';

    @TestVisible
    private Schema.DescribeSObjectResult objectDescribe;

    public class DMLServiceException extends Exception { }

    @TestVisible
    public DMLService(SObjectType sObjectType) {
        objectDescribe = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual SObject create(SObject record) {
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

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual SObject update(SObject record) {
        if (!objectDescribe.isUpdatable()) {
            throw new DMLServiceException(ERROR_UPDATE);
        }

        update record;
        return record;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual List<SObject> update(List<SObject> records) {
        if (!objectDescribe.isUpdatable()) {
            throw new DMLServiceException(ERROR_UPDATE);
        }

        update records;
        return records;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual void delete(SObject record) {
        if (!objectDescribe.isDeletable()) {
            throw new DMLServiceException(ERROR_DELETE);
        }

        delete record;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public virtual List<SObject> delete(List<SObject> records) {
        if (!objectDescribe.isDeletable()) {
            throw new DMLServiceException(ERROR_DELETE);
        }

        insert records;
    }
}