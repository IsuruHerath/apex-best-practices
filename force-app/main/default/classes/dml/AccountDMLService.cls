public inherited sharing class AccountDMLService extends DMLService {
    @TestVisible
    private static AccountDMLService service;

    @TestVisible
    private AccountDMLService() {
        super(Schema.Account.SObjectType);
    }

    public static AccountDMLService getInstance() {
        if(service == null) {
            service = new AccountDMLService();
        }

        return service;
    }

    public virtual Account create(Account record) {
        return (Account) super.create(record);
    }

    public virtual List<Account> create(List<Account> records) {
        return (List<Account>) super.create(records);
    }
}