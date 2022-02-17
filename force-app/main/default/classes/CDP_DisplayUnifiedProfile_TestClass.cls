@isTest
public with sharing class CDP_DisplayUnifiedProfile_TestClass {
  public CDP_DisplayUnifiedProfile_TestClass() {
  }

  @testSetup
  static void setup() {
    //Create common test accounts
    List<Account> testAccounts = new List<Account>();
    Account account = new Account();
    account.Name = 'Infosys';
    testAccounts.add(account);

    insert testAccounts;

    // Create common test contacts
    List<Contact> testContacts = new List<Contact>();
    Contact contact = new Contact();
    contact.FirstName = 'Oliver';
    contact.LastName = 'Miller';
    contact.Email = 'oliver1@gmail.com';
    contact.Secondary_Email__c = 'oliver1@gmail.com';
    contact.Phone = '+493355684338';
    contact.MobilePhone = '+49876543211';
    contact.MailingCity = 'Dearborn';
    contact.MailingStreet = 'Tully Poot.';
    contact.MailingState = 'Florida';
    contact.MailingPostalCode = '124567';
    contact.MailingCountry = ' United States Of America ';
    contact.Job_Function__c = 'Accounting';
    contact.GlobalPartyId = 'CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8';
    contact.AccountId = testAccounts[0].Id;
    contact.Contact_Origin__c = 'Contact Tab';
    testContacts.add(contact);

    insert testContacts;
    system.debug('** testContacts ' + testContacts[0].id);

    //Create common test accounts
    List<Lead> testLeads = new List<Lead>();
    Lead lead = new Lead();
    lead.FirstName = 'Menard';
    lead.LastName = 'Drewe';
    lead.Email = 'mdrewe57@geocities.jp';
    lead.Phone = '+493355684338';
    lead.MobilePhone = '+89567895432';
    lead.City = 'Dearborn';
    lead.Street = 'Tully Poot.';
    lead.State = 'Florida';
    lead.PostalCode = '124567';
    lead.Country = ' United States Of America ';
    lead.Job_Function__c = 'Accounting';
    lead.Company = 'Infosys';
    lead.GlobalPartyId = 'CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8';
    testLeads.add(lead);

    insert testLeads;
  }
  public static String recId = String.valueof(contact.ID);
  public static String adopt = '{"recordID":"0030100000J9V51AAF","sObjectName":"Contact","adoptedEmailValues":{"ContactPointValue":"k.windorfer@dumps.de"},"adoptedSecondaryEmailValues":{"ContactPointValue":"m12@m12german.de"},"adoptedPhoneValues":{"ContactPointValue":"49 (0)8582/9606-14","ContactPointType":"PHONE"},"adoptedMobileValues":null,"adoptedAddressValues":{"addressLine1":"Passauer Str. 45","cityName":"Röhrnbach","stateProvinceName":"","countryName":"Germany","postalCode":"94133"}}';
  public static String adoptLead = '{"recordID":"00Q01000004rciAEAQ","sObjectName":"Lead","adoptedEmailValues":{"ContactPointValue":"k.windorfer@dumps.de"},"adoptedSecondaryEmailValues":{"ContactPointValue":"m12@m12german.de"},"adoptedPhoneValues":{"ContactPointValue":"49 (0)8582/9606-14","ContactPointType":"PHONE"},"adoptedMobileValues":null,"adoptedAddressValues":{"addressLine1":"Passauer Str. 45","cityName":"Röhrnbach","stateProvinceName":"","countryName":"Germany","postalCode":"94133"}}';
  public static String adoptMobile = '{"recordID":"0030100000J9V51AAF","sObjectName":"Contact","adoptedMobileValues":{"ContactPointValue":"+9999988888","ContactPointType":"Mobile"}}';
  public static String adoptLeadMobile = '{"recordID":"00Q01000004rciAEAQ","sObjectName":"Lead","adoptedMobileValues":{"ContactPointValue":"+9999988888","ContactPointType":"Mobile"}}';
  public static String adoptConExcep = '{"recordID":"0030100000J9V51XYZ","sObjectName":"Contact","adoptedEmailValues":{"ContactPointValue":"k.windorferdumps.de"},"adoptedSecondaryEmailValues":{"ContactPointValue":"m12@m12german.de"},"adoptedPhoneValues":{"ContactPointValue":"49 (0)8582/9606-14","ContactPointType":"PHONE"},"adoptedMobileValues":null,"adoptedAddressValues":{"addressLine1":"Passauer Str. 45","cityName":"Röhrnbach","stateProvinceName":"MH","countryName":"DE","postalCode":"ABCDEF"}}';
  public static String adoptLeadExcep = '{"recordID":"00Q01000004rciAABC","sObjectName":"Lead","adoptedEmailValues":{"ContactPointValue":"k.windorferdumps.de"},"adoptedSecondaryEmailValues":{"ContactPointValue":"m12@m12german.de"},"adoptedPhoneValues":{"ContactPointValue":"49 (0)8582/9606-14","ContactPointType":"PHONE"},"adoptedMobileValues":null,"adoptedAddressValues":{"addressLine1":"Passauer Str. 45","cityName":"Röhrnbach","stateProvinceName":"MH","countryName":"DE","postalCode":"ABCDEF"}}';

  public static testMethod void getDataSource() {
    Test.startTest();
    // Setting up the mock response
    CDP_DisplayUnifiedProfile.testdata = '{"startTime":"2022-02-03T07:58:45.634983Z","rowCount":"11","queryId":"677ee311-6b8a-47a1-aa77-64bb43828db1","endTime":"2022-02-03T07:58:58.15391Z","done":"true","data":[{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-12 23:45:45.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"ADDRESS","ContactPoint":"Passauer Str. 45~Röhrnbach~~94133~Germany"},{"SourceRecord":"SFMC,storage_direct_20211222-024817_a95f2034-7eb8-48f7-9e86-87220d64a9e3,98d8c4f2-dc26-11eb-96af-0ee0102191c1","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"EMAIL","ContactPoint":"k.windorfer@dumps.de"},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"EMAIL","ContactPoint":"k.windorfer@dumps.de"},{"SourceRecord":"SFMC,storage_direct_20211222-024817_a95f2034-7eb8-48f7-9e86-87220d64a9e3,98d8c4f2-dc26-11eb-96af-0ee0102191c1","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"INDIVIDUAL","ContactPoint":"Kerstin,Windorfer"},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"INDIVIDUAL","ContactPoint":"Kerstin,Windorfer"},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"MOBILE PHONE","ContactPoint":""},{"SourceRecord":"SFMC,storage_direct_20211222-024817_a95f2034-7eb8-48f7-9e86-87220d64a9e3,98d8c4f2-dc26-11eb-96af-0ee0102191c1","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"MOBILE PHONE","ContactPoint":""},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-12 23:45:45.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"PARTYID","ContactPoint":"Physician Registration Number,"},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-12 23:45:45.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"PHONE","ContactPoint":"49 (0)8582/9606-14"},{"SourceRecord":"Salesforce_00D760000008aLq,Contact,003j0000017mZLDAA2","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"SECONDARY EMAIL","ContactPoint":"m12@m12german.de"},{"SourceRecord":"SFMC,storage_direct_20211222-024817_a95f2034-7eb8-48f7-9e86-87220d64a9e3,98d8c4f2-dc26-11eb-96af-0ee0102191c1","OccuranceCnt":"1","LastModifiedDate":"2021-10-29 14:14:26.000","Id":"a19d76c4-1570-3843-be87-dcd0ecfecebb","ContactPointType":"SECONDARY EMAIL","ContactPoint":"m12@m12german.de"}]}';
    //  Test.setMock(HTTPCalloutMock.class, new CDP_UnifiedProfileDataMock());
    CDP_DisplayUnifiedProfile.displayUnifiedProfile(recId);
    //CDP_DisplayUnifiedProfile.adoptContactDetails(adoptEmail);
    String result = CDP_DisplayUnifiedProfile.adoptContactDetails(adopt);
    CDP_DisplayUnifiedProfile.adoptContactDetails(adoptMobile);
    CDP_DisplayUnifiedProfile.adoptContactDetails(adoptLead);
    CDP_DisplayUnifiedProfile.adoptContactDetails(adoptLeadMobile);
    Test.stopTest();
    System.assertEquals(true, result.contains('Success'));
  }
  /* 
    public static testMethod  void getLeadtest(){
        Test.startTest();
       String result = CDP_DisplayUnifiedProfile.adoptContactDetails(adoptLead);
        Test.stopTest();
        System.assertEquals(true, result.contains('Success'));
    }
        
        public static testMethod  void getConMobiletest(){
        Test.startTest();
        CDP_DisplayUnifiedProfile.adoptContactDetails(adoptMobile);
        Test.stopTest();
        }
            
        public static testMethod void getLeadMobiletest(){
        Test.startTest();
        CDP_DisplayUnifiedProfile.adoptContactDetails(adoptLeadMobile);
        Test.stopTest();
        
        
    }*/
  public static testMethod void getContestExcep() {
    Test.startTest();
    String result = CDP_DisplayUnifiedProfile.adoptContactDetails(
      adoptConExcep
    );
    Test.stopTest();
    System.assertEquals(true, result.contains('Error'));
  }

  /*public static testMethod  void getLeadtestExcep(){
        Test.startTest();
       String result = CDP_DisplayUnifiedProfile.adoptContactDetails(adoptLeadExcep);
        Test.stopTest();
        System.assertEquals(true, result.contains('Error'));
        
    }*/
}
