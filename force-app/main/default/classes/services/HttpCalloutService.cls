public class HttpCalloutService {

    // Private constructor as all methods are static
    private HttpCalloutService() {}

    /**
     * Wrapper class for HttpResponse to make it more accessible, especially for Aura/LWC.
     */
    public class HttpResponseWrapper {
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String status;
        @AuraEnabled public String body;
        @AuraEnabled public Map<String, String> headers;

        public HttpResponseWrapper(HttpResponse response) {
            this.statusCode = response.getStatusCode();
            this.status = response.getStatus();
            this.body = response.getBody();
            this.headers = new Map<String, String>();
            if (response.getHeaderKeys() != null) {
                for (String key : response.getHeaderKeys()) {
                    // Store header keys in lowercase for consistent and easier access
                    this.headers.put(key.toLowerCase(), response.getHeader(key));
                }
            }
        }
    }

    /**
     * Performs an HTTP GET request.
     * @param endpoint The URL endpoint for the request.
     * @param headers A map of request headers.
     * @param timeout The timeout for the request in milliseconds. Defaults to 120000ms (2 minutes) if null or invalid.
     * @return HttpResponseWrapper containing the response details.
     * @throws AuraHandledException if endpoint is blank or if a CalloutException occurs.
     */
    public static HttpResponseWrapper get(String endpoint, Map<String, String> headers, Integer timeout) {
        if (String.isBlank(endpoint)) {
            throw new AuraHandledException('Endpoint cannot be blank for GET request.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');

        if (timeout != null && timeout > 0) {
            req.setTimeout(timeout);
        } else {
            req.setTimeout(120000); // Default timeout
        }

        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            return new HttpResponseWrapper(res);
        } catch (System.CalloutException e) {
            System.debug(LoggingLevel.ERROR, 'HTTP GET Callout Error: ' + e.getMessage() + '\nEndpoint: ' + endpoint);
            throw new AuraHandledException('HTTP GET Callout Failed: ' + e.getMessage());
        }
    }

    /**
     * Performs an HTTP POST request.
     * @param endpoint The URL endpoint for the request.
     * @param requestBody The body of the request.
     * @param headers A map of request headers.
     * @param contentType The Content-Type header value. Defaults to 'application/json'.
     * @param timeout The timeout for the request in milliseconds. Defaults to 120000ms.
     * @return HttpResponseWrapper containing the response details.
     * @throws AuraHandledException if endpoint is blank or if a CalloutException occurs.
     */
    public static HttpResponseWrapper post(String endpoint, String requestBody, Map<String, String> headers, String contentType, Integer timeout) {
        if (String.isBlank(endpoint)) {
            throw new AuraHandledException('Endpoint cannot be blank for POST request.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');

        if (timeout != null && timeout > 0) {
            req.setTimeout(timeout);
        } else {
            req.setTimeout(120000); // Default
        }

        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        
        if (String.isNotBlank(contentType)) {
            req.setHeader('Content-Type', contentType);
        } else {
            req.setHeader('Content-Type', 'application/json'); // Default Content-Type
        }

        if (requestBody != null) {
            req.setBody(requestBody);
        }

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            return new HttpResponseWrapper(res);
        } catch (System.CalloutException e) {
            System.debug(LoggingLevel.ERROR, 'HTTP POST Callout Error: ' + e.getMessage() + '\nEndpoint: ' + endpoint);
            throw new AuraHandledException('HTTP POST Callout Failed: ' + e.getMessage());
        }
    }

    /**
     * Performs an HTTP PUT request.
     * @param endpoint The URL endpoint for the request.
     * @param requestBody The body of the request.
     * @param headers A map of request headers.
     * @param contentType The Content-Type header value. Defaults to 'application/json'.
     * @param timeout The timeout for the request in milliseconds. Defaults to 120000ms.
     * @return HttpResponseWrapper containing the response details.
     * @throws AuraHandledException if endpoint is blank or if a CalloutException occurs.
     */
    public static HttpResponseWrapper put(String endpoint, String requestBody, Map<String, String> headers, String contentType, Integer timeout) {
        if (String.isBlank(endpoint)) {
            throw new AuraHandledException('Endpoint cannot be blank for PUT request.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PUT');

        if (timeout != null && timeout > 0) {
            req.setTimeout(timeout);
        } else {
            req.setTimeout(120000); // Default
        }

        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }
        
        if (String.isNotBlank(contentType)) {
            req.setHeader('Content-Type', contentType);
        } else {
            req.setHeader('Content-Type', 'application/json'); // Default Content-Type
        }

        if (requestBody != null) {
            req.setBody(requestBody);
        }

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            return new HttpResponseWrapper(res);
        } catch (System.CalloutException e) {
            System.debug(LoggingLevel.ERROR, 'HTTP PUT Callout Error: ' + e.getMessage() + '\nEndpoint: ' + endpoint);
            throw new AuraHandledException('HTTP PUT Callout Failed: ' + e.getMessage());
        }
    }

    /**
     * Performs an HTTP DELETE request. (Named deleteCallout as 'delete' is a reserved keyword)
     * @param endpoint The URL endpoint for the request.
     * @param headers A map of request headers.
     * @param timeout The timeout for the request in milliseconds. Defaults to 120000ms.
     * @return HttpResponseWrapper containing the response details.
     * @throws AuraHandledException if endpoint is blank or if a CalloutException occurs.
     */
    public static HttpResponseWrapper deleteCallout(String endpoint, Map<String, String> headers, Integer timeout) {
        if (String.isBlank(endpoint)) {
            throw new AuraHandledException('Endpoint cannot be blank for DELETE request.');
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('DELETE');

        if (timeout != null && timeout > 0) {
            req.setTimeout(timeout);
        } else {
            req.setTimeout(120000); // Default timeout
        }

        if (headers != null) {
            for (String key : headers.keySet()) {
                req.setHeader(key, headers.get(key));
            }
        }

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            return new HttpResponseWrapper(res);
        } catch (System.CalloutException e) {
            System.debug(LoggingLevel.ERROR, 'HTTP DELETE Callout Error: ' + e.getMessage() + '\nEndpoint: ' + endpoint);
            throw new AuraHandledException('HTTP DELETE Callout Failed: ' + e.getMessage());
        }
    }
}
