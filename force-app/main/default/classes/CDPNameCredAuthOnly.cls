/**
 * @description       :
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 02-04-2022
 * @last modified by  : BDirheimer
 **/
public with sharing class CDPNameCredAuthOnly {
  public CDPNameCredAuthOnly() {
    //Profile API
    HttpRequest req = new HttpRequest();
    string query = 'UnifiedIndividual__dlm?fields=ssot__Id__c&filters=[Email__c=junk@junk.com]';
    req.setEndpoint(
      'https://callout:CDPQuery/services/data/v53.0/ssot/profile/' + query
    );
    req.setMethod('GET');
    req.setHeader('Content-Type', 'application/json');
    //req.setBody('{"sql": "SELECT ssot__FirstName__c, ssot__LastName__c, ssot__Id__c, ssot__ExternalRecordId__c, ssot__ExternalSourceId__c,MobilePhone__c, Phone__c, Email__c,Full_Address__c FROM UnifiedIndividual__dlm WHERE Email__c = \'zzmohd@eastman.com\'"}');
    Http http = new Http();
    HttpResponse res = http.send(req);
    system.debug(res.getBody());
  }
  /*
    public string d;
    public Object data;
    public Map<String, CDP_Connect_API__mdt> con = CDP_Connect_API__mdt.getAll();
    public CDP_Connect_API__mdt sc = CDP_Connect_API__mdt.getInstance('m1s010000000064');
    public static void parseJSONString() {
        String jsonStr = '{"data":['+
            '{"indexes":['+ '{"ssot__TelephoneNumber__c","ssot__Id__c"}' +
            '{"fields":[{"name": "ssot__TelephoneNumber__c","ssot__TelephoneNumber__c"}]}]}]}';
            
            JSONParser parser = JSON.createParser(jsonStr);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        data d = (data)parser.readValueAs(data.class);
                        system.debug('indexes:' + d.ssot__TelephoneNumber__c);
                        system.debug('fields: ' + d.ssot__Id__c);
                         String s = JSON.serialize(d);
                    system.debug('Serialized data: ' + d);
                        parser.skipChildren();
                    }
                }
            }
        }
	}
}

public class Data {
    public String ssot__TelephoneNumber__c;
    public String ssot__Id__c;
    
    public Data(String Id, String Phone, List<data> d){
        recordId = id;
        phone = ssot__TelephoneNumber__c;
        fields = d.clone();
    } */

  public static void getProfile() {
    //Profile API
    HttpRequest req = new HttpRequest();
    string query = 'UnifiedIndividual__dlm?fields=ssot__Id__c&filters=[Email__c=junk@junk.com]';
    req.setEndpoint(
      'callout:CDPQuery/services/data/v53.0/ssot/profile/' + query
    );
    req.setMethod('GET');
    req.setHeader('Content-Type', 'application/json');
    //req.setBody('{"sql": "SELECT ssot__FirstName__c, ssot__LastName__c, ssot__Id__c, ssot__ExternalRecordId__c, ssot__ExternalSourceId__c,MobilePhone__c, Phone__c, Email__c,Full_Address__c FROM UnifiedIndividual__dlm WHERE Email__c = \'zzmohd@eastman.com\'"}');
    Http http = new Http();
    HttpResponse res = http.send(req);
    system.debug('*** response profile ' + res.getBody());
  }

  public static void getQuery() {
    //Profile API
    HttpRequest req = new HttpRequest();
    // string query = 'UnifiedIndividual__dlm?fields=ssot__Id__c&filters=[Email__c=junk@junk.com]';
    req.setEndpoint('callout:CDPQuery/services/data/v53.0/ssot/query/');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(
      '{"sql": "SELECT * FROM UnifiedIndividual__dlm WHERE ssot__Id__c = \'cce0fdad-9a0a-3c37-a7ff-149101ef463b\'"}'
    );
    Http http = new Http();
    HttpResponse res = http.send(req);
    system.debug('*** response query ' + res.getBody());
  }
}
