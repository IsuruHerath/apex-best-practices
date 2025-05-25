@isTest
private class HttpCalloutServiceTest {

    private static final String TEST_ENDPOINT = 'https://api.example.com/test';

    // --- Mock Implementations ---
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String body;
        private Map<String, String> responseHeaders;
        private String expectedMethod; // To assert method in request
        private String expectedBody;   // To assert body in request
        private String expectedContentType; // To assert Content-Type

        public MockHttpResponseGenerator(Integer sc, String st, String b, Map<String, String> rh) {
            this.statusCode = sc;
            this.status = st;
            this.body = b;
            this.responseHeaders = rh;
        }
        
        public MockHttpResponseGenerator expectMethod(String method) { this.expectedMethod = method; return this; }
        public MockHttpResponseGenerator expectBody(String body) { this.expectedBody = body; return this; }
        public MockHttpResponseGenerator expectContentType(String contentType) { this.expectedContentType = contentType; return this; }


        public HttpResponse respond(HttpRequest req) {
            if (this.expectedMethod != null) Assert.areEqual(this.expectedMethod, req.getMethod(), 'Request method mismatch.');
            if (this.expectedBody != null) Assert.areEqual(this.expectedBody, req.getBody(), 'Request body mismatch.');
            if (this.expectedContentType != null) Assert.areEqual(this.expectedContentType, req.getHeader('Content-Type'), 'Request Content-Type mismatch.');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            if (this.body != null) res.setBody(this.body);
            if (this.responseHeaders != null) {
                for (String key : this.responseHeaders.keySet()) {
                    res.setHeader(key, this.responseHeaders.get(key));
                }
            }
            return res;
        }
    }

    private class ExceptionThrowingMock implements HttpCalloutMock {
        private String exceptionMessage;
        public ExceptionThrowingMock(String message) { this.exceptionMessage = message; }
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException(this.exceptionMessage);
        }
    }
    
    private static void expectAuraHandledException(String serviceMethod, String expectedMessagePart) {
        Exception caughtException = null;
        try {
            if(serviceMethod == 'get_blank') HttpCalloutService.get('', null, null);
            else if(serviceMethod == 'post_blank') HttpCalloutService.post('', null, null, null, null);
            // Add other blank endpoint checks if necessary for put/delete
        } catch (Exception e) {
            caughtException = e;
        }
        Assert.isNotNull(caughtException, 'Expected AuraHandledException for ' + serviceMethod);
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException type for ' + serviceMethod);
        if(caughtException != null && expectedMessagePart != null) {
            Assert.isTrue(caughtException.getMessage().contains(expectedMessagePart), 
                'Unexpected exception message for ' + serviceMethod + '. Expected: "' + expectedMessagePart + 
                '". Actual: "' + caughtException.getMessage() + '"');
        }
    }

    // --- Test Methods for GET ---
    @isTest
    static void testGet_Success() {
        Map<String, String> mockHeaders = new Map<String, String>{'Content-Type' => 'application/json', 'X-Custom-Header' => 'TestValue'};
        String mockBody = '{"data":"success"}';
        HttpCalloutMock mock = new MockHttpResponseGenerator(200, 'OK', mockBody, mockHeaders);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.get(TEST_ENDPOINT, null, 10000);
        Test.stopTest();

        Assert.isNotNull(response, 'Response wrapper should not be null.');
        Assert.areEqual(200, response.statusCode, 'Status code mismatch.');
        Assert.areEqual(mockBody, response.body, 'Response body mismatch.');
        Assert.isNotNull(response.headers, 'Response headers map should not be null.');
        // Header keys are lowercased by the wrapper
        Assert.areEqual('application/json', response.headers.get('content-type'), 'Content-Type header mismatch.');
        Assert.areEqual('TestValue', response.headers.get('x-custom-header'), 'Custom header mismatch.');
    }

    @isTest
    static void testGet_Error() {
        HttpCalloutMock mock = new MockHttpResponseGenerator(500, 'Server Error', '{"error":"Internal Server Error"}', null);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.get(TEST_ENDPOINT, null, 10000);
        Test.stopTest();
        Assert.areEqual(500, response.statusCode, 'Status code for error mismatch.');
    }

    @isTest
    static void testGet_TimeoutOrCalloutException() {
        HttpCalloutMock mock = new ExceptionThrowingMock('Simulated read timed out.');
        Exception caughtException = null;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        try {
            services.HttpCalloutService.get(TEST_ENDPOINT, null, 5000);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();
        Assert.isNotNull(caughtException, 'Expected an exception for callout failure.');
        Assert.isTrue(caughtException instanceof AuraHandledException, 'Expected AuraHandledException for callout failure.');
        if(caughtException != null) Assert.isTrue(caughtException.getMessage().contains('Simulated read timed out'), 'Incorrect exception message.');
    }

    @isTest static void testGet_BlankEndpoint() { expectAuraHandledException('get_blank', 'Endpoint cannot be blank'); }

    // --- Test Methods for POST ---
    @isTest
    static void testPost_Success() {
        String requestBody = '{"name":"Test"}';
        HttpCalloutMock mock = new MockHttpResponseGenerator(201, 'Created', '{"id":"123"}', null)
            .expectMethod('POST')
            .expectBody(requestBody)
            .expectContentType('application/json');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.post(TEST_ENDPOINT, requestBody, null, 'application/json', 10000);
        Test.stopTest();
        Assert.areEqual(201, response.statusCode);
        Assert.areEqual('{"id":"123"}', response.body);
    }
    
    @isTest
    static void testPost_Error() {
        HttpCalloutMock mock = new MockHttpResponseGenerator(400, 'Bad Request', null, null).expectMethod('POST');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.post(TEST_ENDPOINT, '{}', null, 'application/json', 10000);
        Test.stopTest();
        Assert.areEqual(400, response.statusCode);
    }

    @isTest static void testPost_BlankEndpoint() { expectAuraHandledException('post_blank', 'Endpoint cannot be blank'); }

    @isTest
    static void testPost_DefaultContentType() {
        HttpCalloutMock mock = new MockHttpResponseGenerator(200, 'OK', null, null)
            .expectMethod('POST')
            .expectContentType('application/json'); // Service defaults to this

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.post(TEST_ENDPOINT, '{}', null, null, 10000); // Pass null contentType
        Test.stopTest();
        // Assertions are within the mock's respond method
    }

    // --- Test Methods for PUT ---
    @isTest
    static void testPut_Success() {
        String requestBody = '{"name":"Updated Test"}';
        HttpCalloutMock mock = new MockHttpResponseGenerator(200, 'OK', '{"status":"updated"}', null)
            .expectMethod('PUT')
            .expectBody(requestBody)
            .expectContentType('application/xml'); // Test with a different content type

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.put(TEST_ENDPOINT, requestBody, null, 'application/xml', 10000);
        Test.stopTest();
        Assert.areEqual(200, response.statusCode);
        Assert.areEqual('{"status":"updated"}', response.body);
    }

    @isTest
    static void testPut_Error() {
        HttpCalloutMock mock = new MockHttpResponseGenerator(503, 'Service Unavailable', null, null).expectMethod('PUT');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.put(TEST_ENDPOINT, '{}', null, 'application/json', 10000);
        Test.stopTest();
        Assert.areEqual(503, response.statusCode);
    }

    // --- Test Methods for DELETE ---
    @isTest
    static void testDelete_Success() {
        // DELETE often returns 204 No Content or 200 OK with a body
        HttpCalloutMock mock = new MockHttpResponseGenerator(204, 'No Content', null, null).expectMethod('DELETE');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.deleteCallout(TEST_ENDPOINT, null, 10000);
        Test.stopTest();
        Assert.areEqual(204, response.statusCode);
    }

    @isTest
    static void testDelete_Error() {
        HttpCalloutMock mock = new MockHttpResponseGenerator(404, 'Not Found', null, null).expectMethod('DELETE');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        services.HttpCalloutService.HttpResponseWrapper response = services.HttpCalloutService.deleteCallout(TEST_ENDPOINT, null, 10000);
        Test.stopTest();
        Assert.areEqual(404, response.statusCode);
    }
}
