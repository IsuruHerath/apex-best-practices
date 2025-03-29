public with sharing class AccountBuilder {
    private Id accountId;
    private String name;

    public static AccountBuilder getBuilder() {
        return new AccountBuilder();
    }

    public AccountBuilder setId(Id id) {
        this.accountId = id;
        return this;
    }

    public AccountBuilder setName(String name) {
        this.name = name;
        return this;
    }

    public Account build() {
        return new Account(
            Id = this.accountId,
            Name = this.name
        );
    }
}