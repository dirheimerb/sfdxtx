/**
 * @description       : 
 * @author            : BDirheimer
 * @group             : 
 * @last modified on  : 02-07-2022
 * @last modified by  : BDirheimer
**/
public with sharing class CDPRestTable {
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
    public string UnifiedContactPointEmail__dlm;

    public static ConnectApi.CdpQueryOutput queryProfileApi(String dataModelName, String id, String searchKey, String fields);
    public static ConnectApi.CdpQueryInput queryANSISql(ConnectApi.CdpQueryInput searchKey)



    }
}
