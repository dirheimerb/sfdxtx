@isTest
public with sharing class GlobalProfileDataTest {
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

  public static testMethod void getGlobalProfileForEmail() {
    Test.startTest();
    // Setting up the mock response
    Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());

    Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
    List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();
    //System.runAs(u){
    customer360Data = GlobalProfileData.getGlobalProfile('oliver@gmail.com');
    //}
    allData = customer360Data.allData;

    //get contacts
    List<Contact> contacts = [
      SELECT
        id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Secondary_Email__c,
        Phone,
        MobilePhone,
        Extension__c,
        MailingStreet,
        MailingState,
        MailingCountry,
        MailingPostalCode,
        MailingStateCode,
        MailingCity,
        OtherStreet
      FROM Contact
    ];

    //get leads
    List<Lead> leads = [
      SELECT
        Id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Extension__c,
        Phone,
        MobilePhone,
        Street,
        State,
        Country,
        PostalCode,
        City,
        StateCode
      FROM Lead
    ];

    GlobalProfileData.appendLocalContactsToResponse(allData, contacts);
    GlobalProfileData.appendLocalLeadsToResponse(allData, leads);

    Test.stopTest();
  }
  public static testMethod void getGlobalProfileForPhone() {
    Test.startTest();
    // Setting up the mock response
    Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());

    Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
    List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

    customer360Data = GlobalProfileData.getGlobalProfile('+499876543498');
    allData = customer360Data.allData;

    //get contacts
    List<Contact> contacts = [
      SELECT
        id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Secondary_Email__c,
        Phone,
        MobilePhone,
        Extension__c,
        MailingStreet,
        MailingState,
        MailingCountry,
        MailingPostalCode,
        MailingStateCode,
        MailingCity,
        OtherStreet
      FROM Contact
    ];

    //get leads
    List<Lead> leads = [
      SELECT
        Id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Extension__c,
        Phone,
        MobilePhone,
        Street,
        State,
        Country,
        PostalCode,
        City,
        StateCode
      FROM Lead
    ];

    GlobalProfileData.appendLocalContactsToResponse(allData, contacts);
    GlobalProfileData.appendLocalLeadsToResponse(allData, leads);

    Test.stopTest();
  }
  public static testMethod void getGlobalProfileForGlobalParty() {
    Test.startTest();
    // Setting up the mock response
    Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());

    Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
    List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

    customer360Data = GlobalProfileData.getGlobalProfile(
      'CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8'
    );
    allData = customer360Data.allData;

    //get contacts
    List<Contact> contacts = [
      SELECT
        id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Secondary_Email__c,
        Phone,
        MobilePhone,
        Extension__c,
        MailingStreet,
        MailingState,
        MailingCountry,
        MailingPostalCode,
        MailingStateCode,
        MailingCity,
        OtherStreet
      FROM Contact
    ];

    //get leads
    List<Lead> leads = [
      SELECT
        Id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Extension__c,
        Phone,
        MobilePhone,
        Street,
        State,
        Country,
        PostalCode,
        City,
        StateCode
      FROM Lead
    ];

    GlobalProfileData.appendLocalContactsToResponse(allData, contacts);
    GlobalProfileData.appendLocalLeadsToResponse(allData, leads);
    GlobalProfileData.getGlobalPartyId(contacts[0].id);
    GlobalProfileData.getGlobalPartyId(leads[0].id);

    Test.stopTest();
  }
  public static testMethod void getGlobalProfileForLocalSFSCIdLead() {
    Test.startTest();
    // Setting up the mock response
    Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());

    Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
    List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

    //get leads
    List<Lead> leads = [
      SELECT
        Id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Extension__c,
        Phone,
        MobilePhone,
        Street,
        State,
        Country,
        PostalCode,
        City,
        StateCode
      FROM Lead
    ];

    customer360Data = GlobalProfileData.getGlobalProfile(leads[0].id);
    allData = customer360Data.allData;

    GlobalProfileData.appendLocalLeadsToResponse(allData, leads);

    Test.stopTest();
  }
  public static testMethod void getGlobalProfileForLocalSFSCIdContact() {
    Test.startTest();
    // Setting up the mock response
    Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());

    Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
    List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

    //get contacts
    List<Contact> contacts = [
      SELECT
        id,
        GlobalPartyId,
        FirstName,
        LastName,
        Email,
        Secondary_Email__c,
        Phone,
        MobilePhone,
        Extension__c,
        MailingStreet,
        MailingState,
        MailingCountry,
        MailingPostalCode,
        MailingStateCode,
        MailingCity,
        OtherStreet
      FROM Contact
    ];

    customer360Data = GlobalProfileData.getGlobalProfile(contacts[0].id);
    allData = customer360Data.allData;

    GlobalProfileData.appendLocalContactsToResponse(allData, contacts);

    string dataSourceIdContact = '0032g00000NwG0sAAF';
    string dataSourceIdLead = '00Q2g00000NwG0sAAF';
    GlobalProfileData.setContactLeadDetailsLabel(dataSourceIdContact, true);
    GlobalProfileData.setContactLeadDetailsLabel(dataSourceIdLead, true);

    Test.stopTest();
  }
}