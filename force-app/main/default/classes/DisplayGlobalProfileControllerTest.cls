/*
  @description       : 
  @author            : Arjita Marelay
  @group             : 
  @last modified on  : 09-16-2021
  @last modified by  : BDirheimer
  Modifications Log 
  Ver   Date         Author       Modification
  1.0   06-15-2021   Arjita Marelay   Initial Version
*/
@isTest
public with sharing class DisplayGlobalProfileControllerTest {
  @TestSetup
  static void testSetupData() {
    Contact contactRec = new Contact();
    contactRec.FirstName = 'Test';
    contactRec.LastName = 'Contact';
    contactRec.Email = 'test@test.com';
    contactRec.Phone = '8888877777';
    contactRec.Job_Function__c = 'Accounting';
    contactRec.MailingCountry = 'United States of America';
    contactRec.Contact_Origin__c = 'Contact Tab';
    insert contactRec;

    Lead leadRec = new Lead();
    leadRec.FirstName = 'Test';
    leadRec.LastName = 'Test';
    leadRec.Email = 'test@test.com';
    leadRec.Phone = '7777788888';
    leadRec.Company = 'Infosys';
    leadRec.Country = 'United States of America';
    insert leadRec;
  }

  private static Contact getContactRec() {
    return [SELECT Id, Email FROM Contact LIMIT 1];
  }

  private static Lead getLeadRec() {
    return [SELECT Id FROM Lead LIMIT 1];
  }

  @isTest
  private static void adoptContactDetailsForContactPhoneTest() {
    Contact contactRec = getContactRec();
    String requestJSON =
      '{"recordID":"' +
      contactRec.Id +
      '","sObjectName":"Contact","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Phone"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"California","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    Contact contactRecAfterUpdate = getContactRec();
    Test.stopTest();
    System.assertEquals('Success', result);
    System.assertEquals('test12@test.com', contactRecAfterUpdate.Email);
  }

  @isTest
  private static void adoptContactDetailsForContactPhoneWithExceptionTest() {
    Contact contactRec = getContactRec();
    String requestJSON =
      '{"recordID":"' +
      contactRec.Id +
      '","sObjectName":"Contact","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Phone"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"CA","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    system.debug('** result ' + result);
    Test.stopTest();
    System.assertEquals(true, result.contains('Success'));
  }

  @isTest
  private static void adoptContactDetailsForContactMobileTest() {
    Contact contactRec = getContactRec();
    String requestJSON =
      '{"recordID":"' +
      contactRec.Id +
      '","sObjectName":"Contact","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Mobile"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"California","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    Contact contactRecAfterUpdate = getContactRec();
    Test.stopTest();
    System.assertEquals('Success', result);
    System.assertEquals('test12@test.com', contactRecAfterUpdate.Email);
  }

  @isTest
  private static void adoptContactDetailsForLeadPhoneTest() {
    Lead leadRec = getLeadRec();
    String requestJSON =
      '{"recordID":"' +
      leadRec.Id +
      '","sObjectName":"Lead","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Phone"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"CA","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    Test.stopTest();
    System.assertEquals('Success', result);
  }

  @isTest
  private static void adoptContactDetailsForLeadPhoneWithExceptionTest() {
    Lead leadRec = getLeadRec();
    String requestJSON =
      '{"recordID":"' +
      leadRec.Id +
      '","sObjectName":"Lead","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Phone"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"California","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    Test.stopTest();
    System.assertEquals(false, result.contains('Error'));
  }

  @isTest
  private static void adoptContactDetailsForLeadMobileTest() {
    Lead leadRec = getLeadRec();
    String requestJSON =
      '{"recordID":"' +
      leadRec.Id +
      '","sObjectName":"Lead","adoptedEmailValues":{"ContactPointValue":"test12@test.com"},"adoptedPhoneValues":{"ContactPointValue":"+9999988888","ContactPointType":"Mobile"},"adoptedAddressValues":{"addressLine1":"TestAdd","cityName":"testCity","stateProvinceCode":"CA","countryName":"United States of America","postalCode":"200201"}}';
    Test.startTest();
    String result = DisplayGlobalProfileController.adoptContactDetails(
      requestJSON
    );
    Test.stopTest();
    System.assertEquals('Success', result);
  }

  @isTest
  private static void getCustomer360DataTest() {
    String dummyResponse = '{"results":[{"creTenantId":"creiad000007kn4","globalPartyId":"CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8","individual":{"globalPartyId":"CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8","firstName":"Oliver","lastName":"Miller","restrictionOfProcessingRequested":false,"forgetThisIndividual":false,"contactPoints":[{"contactPointTypeName":"Address","addressContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"ac4f1ffa-2df0-489a-b6aa-747b904122d0","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"addressLine1":"West Test Court","cityName":"Kuna","postalCode":"83634","countryName":"United States of America","isBilling":false,"isShipping":true}},{"contactPointTypeName":"Email","emailContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"0d18efe2-566c-4b36-8b3d-563f02288d78","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"emailAddress":"oliver@gmail.com","emailMailBox":"oliver","emailDomain":"gmail.com"}},{"contactPointTypeName":"Phone","phoneContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"d615fd76-5279-441e-bd4b-61e87f1aa571","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"phoneCountryCode":"49","telephoneNumber":"9876543498","formattedInternationalPhoneNumber":"+49 9876 543498","formattedE164PhoneNumber":"+499876543498","formattedNationalPhoneNumber":"09876 543498","phoneType":"Mobile","isSMSCapable":false,"isFaxCapable":false}},{"contactPointTypeName":"Phone","phoneContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"b8db803e-b6f7-49c2-8bfb-a902fbd514b0","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"phoneCountryCode":"49","telephoneNumber":"876543211 ext 121","extensionNumber":"121","formattedInternationalPhoneNumber":"+49 8765 43211 ext. 121","formattedE164PhoneNumber":"+49876543211","formattedNationalPhoneNumber":"08765 43211 ext. 121","phoneType":"Home","isSMSCapable":false,"isFaxCapable":false}}],"partyIdentification":[{"identifierName":"Government Health Care","identificationNumber":"125678","issuedDate":1624004955609,"issuedByAuthority":"Government Health Care Identification","globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"2517642f-555a-45d4-9104-0c4a44638262","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1}]},"auditRecords":[{"activeFromDate":1624004955609,"activeToDate":253402214400000,"dataSourceLineage":[{"lineageType":"InputRecord","lineageTypeId":"CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c","dataSourceName":"CRM_DEVCDI","tenantName":"CRM_DEVCDI","tenantId":"00D2g0000000jHsEAI","sourceObjectName":"Lead","sourceRecordID":"0032g00000NjTiyAAF","createdDate":1624004955609,"lineageStatus":"Active","lineageEndDateTime":253402214400000}]}],"createDate":1624004979661,"updateDate":1624004979661,"status":"Active","numContactPoints":4,"numPartyIdentifiers":1,"numDataSources":1}],"responseMetadata":{"totalCount":1,"responseCount":1}}';
    Test.startTest();
    DisplayGlobalProfileController.globalProfileFinalResponse result = DisplayGlobalProfileController.getCustomer360Data(
      dummyResponse
    );
    Test.stopTest();
    System.assertEquals('Oliver', result.firstName);
    System.assertNotEquals('Error', result.status);
  }

  @isTest
  private static void displayGlobalProfileForContactErrorTest() {
    DisplayGlobalProfileControllerMock mockClassObj = new DisplayGlobalProfileControllerMock();
    mockClassObj.setStatus('Error');
    Test.setMock(HttpCalloutMock.class, mockClassObj);
    Contact conRec = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    DisplayGlobalProfileController.globalProfileFinalResponse result = DisplayGlobalProfileController.displayGlobalProfile(
      conRec.Id
    );
    Test.stopTest();
    System.assertEquals('Error', result.status);
    System.assertNotEquals('Oliver', result.firstName);
  }

  @isTest
  private static void displayGlobalProfileForContactExceptionTest() {
    DisplayGlobalProfileControllerMock mockClassObj = new DisplayGlobalProfileControllerMock();
    mockClassObj.setStatus('Error');
    Test.setMock(HttpCalloutMock.class, mockClassObj);
    Contact conRec = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    DisplayGlobalProfileController.globalProfileFinalResponse result = DisplayGlobalProfileController.displayGlobalProfile(
      conRec.Id + 'XX'
    );
    Test.stopTest();
    System.assertEquals('Error', result.status);
    System.assertNotEquals('Oliver', result.firstName);
  }

  @isTest
  private static void displayGlobalProfileForContactSuccessTest() {
    DisplayGlobalProfileControllerMock mockClassObj = new DisplayGlobalProfileControllerMock();
    mockClassObj.setStatus('Success');
    Test.setMock(HttpCalloutMock.class, mockClassObj);
    Contact conRec = [SELECT Id FROM Contact LIMIT 1];
    Test.startTest();
    DisplayGlobalProfileController.globalProfileFinalResponse result = DisplayGlobalProfileController.displayGlobalProfile(
      conRec.Id
    );
    Test.stopTest();
    System.assertEquals('Oliver', result.firstName);
    System.assertNotEquals('Error', result.status);
  }

  @isTest
  private static void displayGlobalProfileForLeadTest() {
    Test.setMock(
      HttpCalloutMock.class,
      new DisplayGlobalProfileControllerMock()
    );
    Lead leadRec = [SELECT Id FROM Lead LIMIT 1];
    Test.startTest();
    DisplayGlobalProfileController.globalProfileFinalResponse result = DisplayGlobalProfileController.displayGlobalProfile(
      leadRec.Id
    );
    Test.stopTest();
    System.assertEquals('Error', result.status);
    System.assertNotEquals('Oliver', result.firstName);
  }
}
