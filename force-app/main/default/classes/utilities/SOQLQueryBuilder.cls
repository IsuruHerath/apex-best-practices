public class SOQLQueryBuilder {

    private String sObjectName;
    private List<String> selectFields = new List<String>();
    private List<String> whereClauses = new List<String>();
    private String orderByField;
    private String orderByDirection = 'ASC'; // Default to ASC
    private Integer limitCount;
    private Map<String, Object> bindVariables = new Map<String, Object>();
    private Integer bindCount = 0;

    // Custom exception for illegal arguments
    public class IllegalArgumentException extends Exception {}

    /**
     * Constructor for the SOQLQueryBuilder.
     * @param sObjectName The API name of the SObject to query.
     * @throws IllegalArgumentException if sObjectName is blank.
     */
    public SOQLQueryBuilder(String sObjectName) {
        if (String.isBlank(sObjectName)) {
            throw new IllegalArgumentException('sObjectName cannot be blank.');
        }
        // Basic sanitization for sObjectName to prevent SOQL issues, though it's used in FROM.
        // More robust validation might involve checking against Schema.getGlobalDescribe().
        this.sObjectName = String.escapeSingleQuotes(sObjectName);
    }

    private String getNextBindName() {
        return 'bind' + (this.bindCount++);
    }

    /**
     * Adds a list of fields to the SELECT clause.
     * @param fields A list of field API names.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder selectFields(List<String> fields) {
        if (fields != null && !fields.isEmpty()) {
            for(String field : fields) {
                if(String.isNotBlank(field)) {
                    this.selectFields.add(String.escapeSingleQuotes(field.trim()));
                }
            }
        }
        return this;
    }

    /**
     * Adds a single field to the SELECT clause.
     * @param field The field API name.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder selectField(String field) {
        if (String.isNotBlank(field)) {
            this.selectFields.add(String.escapeSingleQuotes(field.trim()));
        }
        return this;
    }

    /**
     * Adds an 'equals' condition to the WHERE clause.
     * @param field The field API name.
     * @param value The value to compare against.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder whereEquals(String field, Object value) {
        if (String.isNotBlank(field)) {
            String bindName = getNextBindName();
            this.whereClauses.add(String.escapeSingleQuotes(field.trim()) + ' = :' + bindName);
            this.bindVariables.put(bindName, value);
        }
        return this;
    }

    /**
     * Adds an 'IN' condition to the WHERE clause.
     * @param field The field API name.
     * @param values A list of values to compare against.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder whereIn(String field, List<Object> values) {
        if (String.isNotBlank(field) && values != null && !values.isEmpty()) {
            String bindName = getNextBindName();
            this.whereClauses.add(String.escapeSingleQuotes(field.trim()) + ' IN :' + bindName);
            this.bindVariables.put(bindName, values);
        }
        return this;
    }

    /**
     * Sets the ORDER BY clause.
     * @param field The field API name to order by.
     * @param direction The direction ('ASC' or 'DESC'). Defaults to 'ASC' if invalid.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder orderBy(String field, String direction) {
        if (String.isNotBlank(field)) {
            this.orderByField = String.escapeSingleQuotes(field.trim());
            if (String.isNotBlank(direction)) {
                String upperDirection = direction.toUpperCase().trim();
                if (upperDirection == 'ASC' || upperDirection == 'DESC') {
                    this.orderByDirection = upperDirection;
                } else {
                    this.orderByDirection = 'ASC'; // Default to ASC if invalid
                }
            } else {
                this.orderByDirection = 'ASC'; // Default if direction is blank
            }
        }
        return this;
    }

    /**
     * Sets the LIMIT clause.
     * @param count The maximum number of records to return.
     * @return The current SOQLQueryBuilder instance for chaining.
     */
    public SOQLQueryBuilder limitResults(Integer count) {
        if (count != null && count > 0) {
            this.limitCount = count;
        }
        return this;
    }

    /**
     * Builds the SOQL query string.
     * @return The constructed SOQL query string.
     */
    public String build() {
        String query = 'SELECT ';

        if (this.selectFields.isEmpty()) {
            query += 'Id'; // Default to SELECT Id if no fields specified
        } else {
            // Join fields, ensuring no duplicates if added multiple ways (though current list doesn't prevent it)
            query += String.join(new List<String>(new Set<String>(this.selectFields)), ', ');
        }

        query += ' FROM ' + this.sObjectName;

        if (!this.whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(this.whereClauses, ' AND ');
        }

        if (String.isNotBlank(this.orderByField)) {
            query += ' ORDER BY ' + this.orderByField + ' ' + this.orderByDirection;
        }

        if (this.limitCount != null) {
            query += ' LIMIT ' + this.limitCount;
        }
        System.debug('Generated SOQL Query: ' + query);
        System.debug('Bind Variables: ' + this.bindVariables);
        return query;
    }

    /**
     * Executes the built SOQL query.
     * @return A list of SObjects resulting from the query.
     * @throws AuraHandledException if the query fails.
     */
    public List<SObject> execute() {
        String queryString = build();
        try {
            // Consider making AccessLevel configurable if needed, USER_MODE is a secure default.
            return Database.queryWithBinds(queryString, this.bindVariables, AccessLevel.USER_MODE);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SOQL Query Execution Error for query "' + queryString + 
                                           '" with binds "' + this.bindVariables + 
                                           '". Error: ' + e.getMessage() + 
                                           '\nStack Trace: ' + e.getStackTraceString());
            // Re-throw as a type that can be handled by Aura/LWC if this service is used there.
            // Or a custom exception type specific to this builder.
            throw new AuraHandledException('Query execution failed. Details: ' + e.getMessage());
        }
    }
}
