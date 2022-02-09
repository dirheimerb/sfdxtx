/**
 * @description       :
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 02-07-2022
 * @last modified by  : BDirheimer
 **/

/**
 * @description This class contains the 'data transfer object' details.
 * @see CDPRestSearch
 */
public with sharing class CDPRestSearchModel {
  public List<Integer> searchArray;
  public String emailBody;
  public String individualBody;
  public String phoneBody;
  public String mobilePhoneBody;
  public String seconeEmailBody;
  public String addressBody;
  public String unifiedLinkBody;
  public Integer arrayKey;
  public Object searchObject;

  /**
   * @description Object to handle nested json response
   */
  public class CDPRestSearchObject {
    public String MobilePhone__c;
    public String Phone__c;
    public String ssot__FirstName__c;
    public String ssot__LastName__c;
    public String ssot__Id__c;
    public String Email__c;
    public String Secondary_Email__c;
    public String ssot__ExternalSourceId__c;
    public String Street__c;
    public String City__c;
    public String State__c;
    public String Postal_Code__c;
    public String Country__c;
    public String UnifiedRecordId__c;
    public String ssot__DataSourceObjectId__c;
    public String ssot__DataSourceId__c;
  }

  @AuraEnabled(Cacheable=true) public String Id {get;set;}
  @AuraEnabled(Cacheable=true) public String firstName {get;set;}
  @AuraEnabled(Cacheable=true) public String lastName {get;set;}
  @AuraEnabled(Cacheable=true) public String email {get;set;}
  @AuraEnabled(Cacheable=true) public String secondaryEmail {get;set;}
  @AuraEnabled(Cacheable=true) public String phone {get;set;}
  @AuraEnabled(Cacheable=true) public String mobilePhone {get;set;}
  @AuraEnabled(Cacheable=true) public String street {get;set;}
  @AuraEnabled(Cacheable=true) public String otherStreet {get; set;}
  @AuraEnabled(Cacheable=true) public String city {get;set;}
  @AuraEnabled(Cacheable=true) public String state {get;set;}
  @AuraEnabled(Cacheable=true) public String postalCode {get;set;}
  @AuraEnabled(Cacheable=true) public String country {get;set;}

  /**
   * @description parsing the provided json string into a list of objects
   * @param json
   * @return list
   */
  public static List<CDPRestSearchModel> parse(String json) {
    return (List<CDPRestSearchModel>) System.JSON.deserialize(
      json,
      List<CDPRestSearchModel>.class
    );
  }
}
