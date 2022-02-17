/**  Signature
 * @method public static ConnectApi.CdpQueryOutput queryANSISql(ConnectApi.CdpQueryInput input, 
 * @param Integer batchSize, Integer offset, String orderby)
 * @param searchObject input
 * @Method Type:  ConnectApi.CdpQueryInput
 * A ConnectApi.CdpQueryInput body with the SQL query.
 * @param batchSize
 * @param Type: Integer
 * Number of records to return. Values are from 1–4999. The default value is 4999.
 * offset
 * @param Type: Integer
 * Number of rows to skip before returning results. 
 * The sum of offset and batchSize must be less than 2147483647. 
 * The default value is 0.
 * @param orderby
 * @param Type: String
 * Comma-separated values to sort the results in ascending or descending
 * order, for example, GenderId__c ASC,Occupation__c DESC.
 * Return Value
 * @Method Type: ConnectApi.CdpQueryOutput
 * 
 * This class is used with CDPRestSearchFields
*/

public with sharing class CDPRestTable {
    class TableWrapper{
    @AuraEnabled public List<DataSource.Column> columns {get;set;}
    @AuraEnabled public String phoneTable {get; set;}
    @AuraEnabled public String mobilePhoneTable {get; set;}
    @AuraEnabled public String emailTable {get; set;}
    @AuraEnabled public String addressTable {get; set;}
    @AuraEnabled public String secondEmailTable {get; set;}
    @AuraEnabled public String individualTable {get; set;}
    @AuraEnabled public String phoneLinkTable {get; set;}
    @AuraEnabled public String emailLinkTable {get; set;}
    @AuraEnabled public String addressLinkTable {get; set;}
    @AuraEnabled public String individualLinkTable {get; set;}
    @AuraEnabled public String partyTable {get; set;}
    @AuraEnabled public String partyLinkTable {get; set;}
    
    //  Children of the Data Model by Name
  //  public string UnifiedContactPointEmail__dlm;
    }
    @AuraEnabled public Object searchObject {get;set;}
  //  public static ConnectApi.CdpQueryOutput queryProfileApi(String dataModelName, String id, String searchKey, String fields);
  //  public static ConnectApi.CdpQueryInput queryANSISql(ConnectApi.CdpQueryInput searchKey)
}
