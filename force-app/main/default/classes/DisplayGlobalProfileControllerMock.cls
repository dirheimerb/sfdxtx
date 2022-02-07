/*
  @description       : 
  @author            : Arjita Marelay
  @group             : 
  @last modified on  : 06-15-2021
  @last modified by  : Arjita Marelay
  Modifications Log 
  Ver   Date         Author       Modification
  1.0   06-15-2021   Arjita Marelay   Initial Version
*/
@isTest
global with sharing class DisplayGlobalProfileControllerMock implements HttpCalloutMock {
  private String status;
  public void setStatus(String status) {
    this.status = status;
  }

  global HTTPResponse respond(HTTPRequest request) {
    // Create a fake response
    HttpResponse response = new HttpResponse();
    String dummyResponse = '{"results":[{"creTenantId":"creiad000007kn4","globalPartyId":"CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8","individual":{"globalPartyId":"CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8","firstName":"Oliver","lastName":"Miller","restrictionOfProcessingRequested":false,"forgetThisIndividual":false,"contactPoints":[{"contactPointTypeName":"Address","addressContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"ac4f1ffa-2df0-489a-b6aa-747b904122d0","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"addressLine1":"West Test Court","cityName":"Kuna","postalCode":"83634","countryName":"United States of America","isBilling":false,"isShipping":true}},{"contactPointTypeName":"Email","emailContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"0d18efe2-566c-4b36-8b3d-563f02288d78","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"emailAddress":"oliver@gmail.com","emailMailBox":"oliver","emailDomain":"gmail.com"}},{"contactPointTypeName":"Phone","phoneContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"d615fd76-5279-441e-bd4b-61e87f1aa571","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"phoneCountryCode":"49","telephoneNumber":"9876543498","formattedInternationalPhoneNumber":"+49 9876 543498","formattedE164PhoneNumber":"+499876543498","formattedNationalPhoneNumber":"09876 543498","phoneType":"Mobile","isSMSCapable":false,"isFaxCapable":false}},{"contactPointTypeName":"Phone","phoneContactPoint":{"contactPointBase":{"globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"b8db803e-b6f7-49c2-8bfb-a902fbd514b0","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1,"forPersonalUse":false,"forBusinessUse":false},"phoneCountryCode":"49","telephoneNumber":"876543211 ext 121","extensionNumber":"121","formattedInternationalPhoneNumber":"+49 8765 43211 ext. 121","formattedE164PhoneNumber":"+49876543211","formattedNationalPhoneNumber":"08765 43211 ext. 121","phoneType":"Home","isSMSCapable":false,"isFaxCapable":false}}],"partyIdentification":[{"identifierName":"Government Health Care","identificationNumber":"125678","issuedDate":1624004955609,"issuedByAuthority":"Government Health Care Identification","globalInputIds":["CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c"],"contactPointId":"2517642f-555a-45d4-9104-0c4a44638262","contactPointFirstCreatedDate":1623905666000,"contactPointLastUpdatedDate":1623905671000,"occurrenceCount":1}]},"auditRecords":[{"activeFromDate":1624004955609,"activeToDate":253402214400000,"dataSourceLineage":[{"lineageType":"InputRecord","lineageTypeId":"CRE-creiad000007kn4-giid-e68a02c5-c344-405d-833b-d39ea3aaa13c","dataSourceName":"CRM_DEVCDI","tenantName":"CRM_DEVCDI","tenantId":"00D2g0000000jHsEAI","sourceObjectName":"Lead","sourceRecordID":"0032g00000NjTiyAAF","createdDate":1624004955609,"lineageStatus":"Active","lineageEndDateTime":253402214400000}]}],"createDate":1624004979661,"updateDate":1624004979661,"status":"Active","numContactPoints":4,"numPartyIdentifiers":1,"numDataSources":1}],"responseMetadata":{"totalCount":1,"responseCount":1}}';

    response.setHeader('Content-Type', 'application/json');
    if (status == 'Success') {
      response.setStatus('OK');
      response.setStatusCode(200);
      response.setBody(dummyResponse);
    } else if (status == 'Error') {
      response.setStatus('Error');
      response.setStatusCode(404);
      response.setBody('Error');
    }

    return response;
  }
}