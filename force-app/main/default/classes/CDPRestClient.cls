/**
 * @description  A static wrapper class to use name credentials with the cdp
 * search.
 *
 * The following classes also use this wrapper class
 * @see CDPSearchController, InvocableCDP...
 * @see Some Private methods are helping with apex testing.  they are only visible to the test classes
 */
public virtual class CDPRestClient {
  @testVisible
  private static Map<String, String> defaultHeaders = new Map<String, String>{
    'Content-Type' => 'application/json',
    'Accept' => 'application/json',
    'Connection' => 'keep-alive'
  };
  @testVisible
  private static String path = '/services/data/v52.0/query';
  /**
   * @description CDPQuery is the name of the Named Credential to use
   */
  @testVisible
  protected String namedCredentialName { get; set; }

  /**
   * @description This ENUM lists the only possible verb for the cdp query api, "POST" and "GET"
   */
  public enum HttpVerb {
    POST
  }

  /**
   * @description Constructor that sets Named Credential
   * @param  CDPQuery name of the Named Credential to use
   */
  public CDPRestClient(String namedCredentialName) {
    this.namedCredentialName = namedCredentialName;
  }

  /**
   * @description This constructor isn't intended for use, which is why it's
   * access modifier is 'Protected'. However, any child class extending
   * this class will either have to implement constructors matching the one
   * above, or this constructor must exist. In order to make this abstraction
   * as useful as possible.
   * Unavailable to anything but inner classes and classes that
   * extend this one.
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  protected CDPRestClient() {
  }

  /**
   * @description Omnibus callout method. This is the primary method for
   * making a REST callout. Most of the other methods in this class serve
   * as convient, syntactic sugar on this method.
   * @param   method Enum HTTP verb to use.
   * @param   path patch component of the callout url i.e. `/services/data/v52.0/ssot/query`
   * @param   body JSON string representing the body of the callout in post situations
   * @param   headers A map<String,String> of headers to use while making this callout
   * @return HttpResponse  HttpResponse Obj
   */
  @testVisible
  @SuppressWarnings('PMD.ExcessiveParameterList')
  protected HttpResponse makeApiCall(
    HttpVerb method,
    String path,
    String body,
    Map<String, String> headers
  ) {
    path = ensureStringEndsInSlash(path);
    HttpRequest apiRequest = new HttpRequest();
    if (method == HttpVerb.POST) {
      apiRequest.setMethod('POST');
    } else {
      apiRequest.setMethod(String.valueOf(method));
    }
    Map<String, String> functionalHeaders = (headers != null)
      ? headers
      : CDPRestClient.defaultHeaders;
    for (String header : functionalHeaders.keySet()) {
      apiRequest.setHeader(header, functionalHeaders.get(header));
    }
    if (String.isNotBlank(body) && (method == HttpVerb.POST)) {
      apiRequest.setBody(body);
    }
    apiRequest.setEndpoint('callout:' + this.namedCredentialName + path);
    Http http = new Http();
    HttpResponse toReturn = http.send(apiRequest);
    return toReturn;
  }

  /**
   * @description  Makes an HTTP Callout to an api resource.
   * Convienence method that assumes the Default Headers.
   * @param method HTTPVerb to use. See the enum above.
   * @param path   Http path component of the URL. ie: `/services/data/v52.0/ssot/query`
   * @param body   Body to send with this call.
   * @return      `HttpResponse`
   */
  @testVisible
  @SuppressWarnings('PMD.ExcessiveParameterList')
  protected HttpResponse makeApiCall(
    HttpVerb method,
    String path,
    String body
  ) {
    return this.makeApiCall(method, path, body, CDPRestClient.defaultHeaders);
  }

  //todo This section is for testing, need to finish test class @Arjita

  /**
     * @description convenience method for a POST Call that only requires a body
     * @param path   Http path component of the URL.
     * @param body   JSON string to post
     * @return     `HTTPResponse`
    
    @testVisible
    protected HttpResponse post(String path, String body) {
        return this.makeApiCall(HttpVerb.POST, path, '', body);
    }
    */

  // Private Helper Methods
  /**
   * @description Ensures that the inputted string ends in a `/`
   * makes callouts more robust.
   * @param   resource string to ensure ends in `/`
   * @return  inputted string with `/` if it didn't already end in one.
   */
  @testVisible
  protected String ensureStringEndsInSlash(String resource) {
    if (resource.endsWith('/')) {
      return resource;
    }
    return resource + '/';
  }
}
