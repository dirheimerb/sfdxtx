public class CDPProfileData {
  private static string CDP_Profile_Endpoint = 'callout:CDP_API/api/v1/profile/ssot__Individual__dlm/searchKey=ssot__DataSourceId__c&fields=ssot__Id__c,ssot__FirstName__c,ssot__LastName__c,ssot__DataSourceId__c&limit=100&filters=[ssot__FirstName__c=Meghan]';

  public static void getCDPQueryAPIResponse() {
    String body = '{"sql":"SELECT ssot__BirthDate__c, City__c, Country__c, ssot__CreatedDate__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c, Email__c, ssot__FirstName__c, ssot__Id__c, ssot__LastModifiedDate__c FROM ssot__Individual__dlm where ssot__FirstName__c =\'Greb\'"}';
    HttpRequest request = new HttpRequest();
    //request.setEndpoint('callout:CDP_API/api/v1/profile/ssot__Individual__dlm/searchKey=ssot__DataSourceId__c&fields=ssot__Id__c,ssot__FirstName__c,ssot__LastName__c,ssot__DataSourceId__c&limit=100&filters=[ssot__FirstName__c=Gleb]');
    //request.setEndpoint('callout:CDP_API/api/v1/query'); //JWT
    request.setEndpoint('callout:CDP_API_New/api/v1/query'); //OAuth 2.0
    //request.setEndpoint('callout:CDP_API/services/data/v52.0/sobjects/Account/describe');
    request.setHeader('Accept', 'application/json');
    //request.setHeader('Content-Type', 'application/json');
    //request.setHeader('Authorization', 'Bearer '+ UserInfo.getSessionId());
    request.setMethod('GET');
    // request.setBody(body);
    Http http = new Http();
    system.debug('***** request' + request);
    HttpResponse httpResponse = http.send(request);
    string response = httpResponse.getBody();
    system.debug('***** response' + response);
  }
}
