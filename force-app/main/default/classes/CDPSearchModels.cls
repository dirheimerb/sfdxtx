/*
@description       : 
@author            : Suseendran
@group             : 
@last modified on  : 12-10-2021
@last modified by  : 
Modifications Log 
Ver   Date         Author       Modification
1.0   12-10-2021   Suseendran   Initial Version
*/
public class CDPSearchModels {
  public class CDPUnifiedProfileResponse {
    @AuraEnabled
    public list<CDPUnifiedProfile> data;
    @AuraEnabled
    public string startTime { get; set; }
    @AuraEnabled
    public string endTime { get; set; }
    @AuraEnabled
    public string rowCount { get; set; }
    @AuraEnabled
    public string queryId { get; set; }
    @AuraEnabled
    public string done { get; set; }
    //@AuraEnabled public list<metadata> metadata;
  }
  public class CDPUnifiedProfile {
    @AuraEnabled
    public string OccuranceCnt { get; set; }
    @AuraEnabled
    public string Id { get; set; }
    @AuraEnabled
    public string ContactPoint { get; set; }
    @AuraEnabled
    public string ContactPointType { get; set; }
    @AuraEnabled
    public string SourceRecord { get; set; }
    @AuraEnabled
    public string LastModifiedDate { get; set; }
  }
  public class metadata {
    @AuraEnabled
    public list<ContactPoint> ContactPoint;
    @AuraEnabled
    public list<ContactPoint> Id;
    @AuraEnabled
    public list<ContactPoint> OccuranceCnt;
    @AuraEnabled
    public list<ContactPoint> ContactPointType;
  }
  public class ContactPoint {
    @AuraEnabled
    public string type { get; set; }
    @AuraEnabled
    public string placeInOrder { get; set; }
    @AuraEnabled
    public string typeCode { get; set; }
  }
  public class UIFinalResponseWrapper {
    @AuraEnabled
    public List<UIFinalResponse> unifiedProfileData { get; set; }
  }

  public class UIFinalResponse {
    @AuraEnabled
    public string firstName { get; set; }
    @AuraEnabled
    public string lastName { get; set; }
    @AuraEnabled
    public string fullName { get; set; }
    @AuraEnabled
    public string UPId { get; set; }
    @AuraEnabled
    public string dataSources { get; set; }
    @AuraEnabled
    public List<EmailAddress> contactPointEmails { get; set; }
    @AuraEnabled
    public List<PhoneNumber> phoneNumbers { get; set; }
    @AuraEnabled
    public List<Address> fullAddress { get; set; }
    @AuraEnabled
    public List<PartyIdentification> partyIdentifications { get; set; }
    //@AuraEnabled public string contactTypeName{get;set;}

    //@AuraEnabled public string sourceObjectName{get;set;}
    @AuraEnabled
    public List<DataSourcePoint> dataSourcePoints { get; set; }
    @AuraEnabled
    public List<string> datasourceObjectNames { get; set; }

    @AuraEnabled
    public boolean canCreateContact { get; set; }
    @AuraEnabled
    public boolean isCDPRecord { get; set; }
  }

  public class PhoneNumber {
    //@AuraEnabled public string dataSourceName{get; set;}
    //@AuraEnabled public string lineageTypeId{get; set;}
    @AuraEnabled
    public string contactType { get; set; } // mobile, home
    @AuraEnabled
    public Boolean isContactType { get; set; }
    @AuraEnabled
    public string telephoneNumber { get; set; }
    @AuraEnabled
    public string formattedInternationalPhoneNumber { get; set; }
    @AuraEnabled
    public string phoneCountryCode { get; set; }
    @AuraEnabled
    public string extensionNumber { get; set; }
    @AuraEnabled
    public DateTime contactPointLastUpdatedDate { get; set; }
  }
  public class Address {
    //@AuraEnabled public string dataSourceName{get; set;}
    //@AuraEnabled public string lineageTypeId{get; set;}
    @AuraEnabled
    public string addressLine1 { get; set; }
    @AuraEnabled
    public string addressLine2 { get; set; }
    @AuraEnabled
    public string addressLine3 { get; set; }
    @AuraEnabled
    public string addressLine4 { get; set; }
    @AuraEnabled
    public string stateProvinceCode { get; set; }
    @AuraEnabled
    public string stateProvinceName { get; set; }
    @AuraEnabled
    public string cityName { get; set; }
    @AuraEnabled
    public string postalCode { get; set; }
    @AuraEnabled
    public string countryName { get; set; }
    @AuraEnabled
    public DateTime contactPointLastUpdatedDate { get; set; }
  }
  public class EmailAddress {
    @AuraEnabled
    public string dataSourceId { get; set; }
    //@AuraEnabled public string lineageTypeId{get; set;}
    @AuraEnabled
    public string emailAddressName { get; set; }
    @AuraEnabled
    public DateTime contactPointLastUpdatedDate { get; set; }
  }
  public class PartyIdentification {
    @AuraEnabled
    public string identifierName { get; set; }
    @AuraEnabled
    public string identificationNumber { get; set; }
    @AuraEnabled
    public List<string> globalInputIds { get; set; }
    @AuraEnabled
    public String contactPointLastUpdatedDate { get; set; }
    @AuraEnabled
    public Datetime contactPointLastUpdatedDatePartyId { get; set; }
  }
  public class DataSourcePoint {
    @AuraEnabled
    public string dataSourceName { get; set; }
    @AuraEnabled
    public string dataSourcerecordId { get; set; }
    @AuraEnabled
    public Boolean isSalesforceRecord { get; set; }
    @AuraEnabled
    public String recordLabel { get; set; }
  }
}
