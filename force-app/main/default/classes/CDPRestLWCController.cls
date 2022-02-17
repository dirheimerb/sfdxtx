/**
 * @description       :
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 02-08-2022
 * @last modified by  : BDirheimer
 **/

public with sharing class CDPRestLWCController {  
  @AuraEnabled(cacheable=true)
    public static List<Contact> getAllContactFields() {
    return [
      SELECT
        Id,
        Email,
        Secondary_Email__c,
        Phone,
        MailingStreet,
        MailingStateCode,
        MailingState,
        MailingPostalCode,
        MailingCountry,
        MailingCity,
        MailingCountryCode,
        LastName,
        FirstName,
        OtherStreet
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
  @AuraEnabled(Cacheable=true)
  public static List<Contact> getEmailFields() {
    return [
      SELECT Id, Email
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
  @AuraEnabled(Cacheable=true)
  public static List<Contact> getSecondEmailAddress() {
    return [
      SELECT Id, Secondary_Email__c
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
  @AuraEnabled(Cacheable=true)
  public static List<Contact> getPhone() {
    return [
      SELECT Id, Phone
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
  @AuraEnabled(Cacheable=true)
  public static List<Contact> getMobilePhone() {
    return [
      SELECT Id, MobilePhone
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
  @AuraEnabled(Cacheable=true)
  public static List<Contact> getContactName() {
    return [
      SELECT Id, firstName, lastName
      FROM Contact
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }

  @AuraEnabled(Cacheable=true)
  public static List<Lead> getCDPLead() {
    return [
      SELECT Id, FirstName, LastName, Email, Phone, MobilePhone
      FROM Lead
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }
}
