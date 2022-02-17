/*
@description       : 
@author            : Kalyani Jagdale
@group             : 
@last modified on  : 09-16-2021
@last modified by  : BDirheimer
Modifications Log 
Ver   Date         Author        Modification
1.0   06-01-2021   Kalyani Jagdale   Initial Version
1.1   06-15-2021   Arjita Marelay
1.2   10-05-2021   BDirheimer and Char Updated State value to be code not name


*/

/*
@description       : 
@author            : Kalyani Jagdale
@group             : 
@last modified on  : 09-16-2021
@last modified by  : BDirheimer
Modifications Log 
Ver   Date         Author        Modification
1.0   06-01-2021   Kalyani Jagdale   Initial Version
@last modified on  : 06-15-2021
@last modified by  : Arjita Marelay
*/

public with sharing class DisplayGlobalProfileViewTest {
  private static string CONTACTID_PREFIX = '003';
  private static string LEADID_PREFIX = '00Q';
  private static string SFDC_DOMAIN = Customer_360_DM__mdt.getInstance(
      'C360_Global_Search'
    )
    .C360_SFDC_Domain__c;
  private static string CONTACT_TYPE_NAME_EMAIL = 'Email';
  private static string CONTACT_TYPE_NAME_PHONE = 'Phone';
  private static string CONTACT_TYPE_NAME_MOBILE = 'Mobile';
  private static string CONTACT_TYPE_NAME_HOME = 'Home';
  private static string SEARCH_PREFIX = 'globalPartyId';
  private static string CONTACT_SOBJECT = 'Contact';
  private static string LEAD_SOBJECT = 'Lead';
  private static string CONTACT_TYPE_NAME_ADDRESS = 'Address';
  private static string ERROR_STATUS = 'Error';
  private static string SUCCESS_STATUS = 'Success';
  private static Boolean isTest = false;
  private static string GLOBAL360_API_ENDPOINT = Customer_360_DM__mdt.getInstance(
      'C360_Global_Search'
    )
    .C360_Global360_Api_Endpoint__c;
  private static final integer GLOBAL360_API_REQUEST_TIMEOUT = Integer.valueOf(
    Customer_360_DM__mdt.getInstance('C360_Global_Search').C360_Timeout_value__c
  );

  @AuraEnabled
  public static globalProfileFinalResponse displayGlobalProfile(
    String recordId
  ) {
    HTTPResponse httpResponse = new HTTPResponse();
    try {
      httpResponse = callGlobalProfileAPI(recordId);
      System.debug('#RES: ' + httpResponse.getBody());
    } catch (Exception ex) {
      globalProfileFinalResponse responseObj = new globalProfileFinalResponse();
      responseObj.status = ERROR_STATUS;
      responseObj.errorMessage = ERROR_STATUS + ' - ' + ex.getMessage();

      // Added on 08 Sep, 2021
      Logger.error(
        'There is an error in the Global Profile. ERROR: ' + ex.getMessage()
      );
      Logger.saveLog();

      return responseObj;
    }

    if (httpResponse.getStatusCode() != 200) {
      globalProfileFinalResponse responseObj = new globalProfileFinalResponse();
      responseObj.status = ERROR_STATUS;
      responseObj.errorMessage = httpResponse.getBody();

      // Added on 08 Sep, 2021
      Logger.error(
        'There is an error in the Global Profile callout. ERROR: ' +
        httpResponse.getBody()
      );
      Logger.saveLog();

      return responseObj;
    }
    string response = httpResponse.getBody();

    globalProfileFinalResponse customer360Data = getCustomer360Data(response);

    // Added on 08 Sep, 2021
    Logger.info('Global profile callout done successfully.');
    Logger.saveLog();

    return customer360Data;
  }

  public static globalProfileFinalResponse getCustomer360Data(string response) {
    Customer360SearchModels.customer360GlobalProfileResponse c360Response = (Customer360SearchModels.customer360GlobalProfileResponse) JSON.deserialize(
      response,
      Customer360SearchModels.customer360GlobalProfileResponse.class
    );
    globalProfileFinalResponse finalResponse = new globalProfileFinalResponse();
    globalProfileFinalResponse responseObj = new globalProfileFinalResponse();

    for (integer i = 0; i < c360Response.results.size(); i++) {
      Customer360SearchModels.customer360globalProfile currentResponse = c360Response
        ?.results[i];

      responseObj.firstName = currentResponse.individual?.firstName;
      responseObj.lastName = currentResponse.individual?.lastName;
      responseObj.globalPartyId = currentResponse.individual?.globalPartyId;
      responseObj.status = SUCCESS_STATUS;

      Map<string, string> dataSourceMap = new Map<string, string>();
      String dataSourceRecordId = '';
      for (Integer j = 0; j < currentResponse?.AuditRecords?.size(); j++) {
        //2
        Customer360SearchModels.AuditRecords auditRecordData = currentResponse.AuditRecords[
          j
        ];
        List<Customer360SearchModels.DataSourceLineage> dataSourceLineageData = currentResponse.AuditRecords[
            j
          ]
          .dataSourceLineage;
        for (
          Customer360SearchModels.DataSourceLineage dataSourceLineageObj : dataSourceLineageData
        ) {
          if (!dataSourceMap.containsKey(dataSourceLineageObj.lineageTypeId)) {
            dataSourceMap.put(
              dataSourceLineageObj.lineageTypeId,
              dataSourceLineageObj.dataSourceName
            );
          }
          system.debug(
            '**dataSourceLineageObj.sourceRecordID ' +
            dataSourceLineageObj.sourceRecordID
          );
          dataSourceRecordId += dataSourceLineageObj.sourceRecordID + ',';
          system.debug('** dataSourceRecordId ' + dataSourceRecordId);
        }
        responseObj.dataSourceRecordId = dataSourceRecordId.substringBeforeLast(
          ','
        );
      }

      //Data according to data source
      responseObj.EmailContactPoints = new List<DisplayGlobalProfileViewTest.contactPointResponse>();
      responseObj.PhoneContactPoints = new List<DisplayGlobalProfileViewTest.contactPointResponse>();
      responseObj.AddressContactPoints = new List<DisplayGlobalProfileViewTest.addressPointResponse>();
      responseObj.PartyIdentificationContactPoints = new List<DisplayGlobalProfileViewTest.contactPointResponse>();

      List<Customer360SearchModels.ContactPoint> contactPoints = currentResponse.individual
        ?.contactPoints;
      // List<DisplayGlobalProfileController.contactPointResponse> contactPointResponse = new List<DisplayGlobalProfileController.contactPointResponse>();
      List<String> dataSourceNames;
      for (Integer j = 0; j < contactPoints?.size(); j++) {
        String dataSourceName = '';
        List<String> globalInputIdsEmail;
        List<String> globalInputIdsPhone;
        List<String> globalInputIdsAddress;

        if (contactPoints[j].emailContactPoint != null) {
          globalInputIdsEmail = contactPoints[j]
            .emailContactPoint.contactPointBase.globalInputIds;
        }
        if (contactPoints[j].phoneContactPoint != null) {
          globalInputIdsPhone = contactPoints[j]
            .phoneContactPoint.contactPointBase.globalInputIds;
        }
        if (contactPoints[j].addressContactPoint != null) {
          globalInputIdsAddress = contactPoints[j]
            .addressContactPoint.contactPointBase.globalInputIds;
        }

        String contactTypeName = contactPoints[j].contactPointTypeName;

        //display contact point email
        if (
          contactTypeName == CONTACT_TYPE_NAME_EMAIL &&
          globalInputIdsEmail.size() > 0
        ) {
          contactPointResponse contactPointEmail = new contactPointResponse();
          for (Integer k = 0; k < globalInputIdsEmail?.size(); k++) {
            System.debug(
              'dataSourceMap.get(globalInputIdsEmail[k]) ' +
              dataSourceMap.get(globalInputIdsEmail[k])
            );
            dataSourceName += dataSourceMap.get(globalInputIdsEmail[k]) + ',';
            System.debug('** datasourcename ' + dataSourceName);
            contactPointEmail.dataSourceName = dataSourceName.substringBeforeLast(
              ','
            );
          }
          contactPointEmail.contactPointValue = contactPoints[j]
            .emailContactPoint.emailAddress;
          contactPointEmail.contactPointType = contactPoints[j]
            .contactPointTypeName;

          // contactPointResponse.add(contactPointEmail);
          responseObj.EmailContactPoints.add(contactPointEmail);

          continue;
        }

        //display contact point phone
        if (
          contactTypeName == CONTACT_TYPE_NAME_PHONE &&
          globalInputIdsPhone.size() > 0
        ) {
          contactPointResponse contactPointPhone = new contactPointResponse();
          for (Integer k = 0; k < globalInputIdsPhone?.size(); k++) {
            dataSourceName += dataSourceMap.get(globalInputIdsPhone[k]) + ',';
            contactPointPhone.dataSourceName = dataSourceName.substringBeforeLast(
              ','
            );
          }
          contactPointPhone.contactPointValue = contactPoints[j]
            .phoneContactPoint.formattedE164PhoneNumber;
          if (
            contactPoints[j].phoneContactPoint.phoneType ==
            CONTACT_TYPE_NAME_HOME
          ) {
            contactPointPhone.contactPointType = CONTACT_TYPE_NAME_PHONE;
          } else {
            contactPointPhone.contactPointType = contactPoints[j]
              .phoneContactPoint.phoneType;
          }

          responseObj.PhoneContactPoints.add(contactPointPhone);

          continue;
        }

        //display contact point email
        if (
          contactTypeName == CONTACT_TYPE_NAME_ADDRESS &&
          globalInputIdsAddress.size() > 0
        ) {
          addressPointResponse contactPointAddress = new addressPointResponse();
          for (Integer k = 0; k < globalInputIdsAddress?.size(); k++) {
            dataSourceName += dataSourceMap.get(globalInputIdsAddress[k]) + ',';
            contactPointAddress.dataSourceName = dataSourceName.substringBeforeLast(
              ','
            );
          }

          Customer360SearchModels.AddressContactPoint addressContactPoint = contactPoints[
              j
            ]
            .addressContactPoint;
          Customer360SearchModels.Address address = buidlAddressContactPoint(
            addressContactPoint
          );
          System.debug('#address: ' + address);
          contactPointAddress.addressLine1 = (address.addressLine1 != null)
            ? address.addressLine1
            : '';
          contactPointAddress.addressLine2 = (address.addressLine2 != null)
            ? address.addressLine2
            : '';
          contactPointAddress.cityName = (address.cityName != null)
            ? address.cityName
            : '';
          contactPointAddress.postalCode = (address.postalCode != null)
            ? address.postalCode
            : '';
          contactPointAddress.stateProvinceCode = (address.stateProvinceCode !=
            null)
            ? address.stateProvinceCode
            : '';
          contactPointAddress.stateProvinceName = (address.stateProvinceName !=
            null)
            ? address.stateProvinceName
            : '';
          contactPointAddress.countryName = (address.countryName != null)
            ? address.countryName
            : '';
          responseObj.AddressContactPoints.add(contactPointAddress);

          continue;
        }
      }

      List<Customer360SearchModels.PartyIdentification> partyIdentification = new List<Customer360SearchModels.PartyIdentification>();
      partyIdentification = currentResponse.individual.partyIdentification;
      List<String> globalInputIdsPartyIdentification;
      for (integer j = 0; j < partyIdentification?.size(); j++) {
        contactPointResponse contactPointPartyId = new contactPointResponse();
        String dataSourceName = '';
        contactPointResponse contactPointResponseObj = new contactPointResponse();
        globalInputIdsPartyIdentification = partyIdentification[j]
          .globalInputIds;
        for (Integer k = 0; k < globalInputIdsPartyIdentification.size(); k++) {
          dataSourceName +=
            dataSourceMap.get(globalInputIdsPartyIdentification[k]) + ',';
          contactPointPartyId.dataSourceName = dataSourceName.substringBeforeLast(
            ','
          );
        }
        contactPointPartyId.contactPointValue = partyIdentification[j]
          .identificationNumber;
        contactPointPartyId.contactPointType = null;
        responseObj.PartyIdentificationContactPoints.add(contactPointPartyId);
      }
      System.debug('** response obj ' + finalResponse);
    }
    return responseObj;
  }

  private static HTTPResponse callGlobalProfileAPI(String recordId) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(GLOBAL360_API_ENDPOINT);
    request.setHeader('x-sfdc-domain', SFDC_DOMAIN);
    request.setHeader('Content-Type', 'application/json');
    request.setMethod('POST');
    request.setTimeout(GLOBAL360_API_REQUEST_TIMEOUT);

    String globalPartyId = getGlobalPartyId(recordId);
    String searchPrefix = SEARCH_PREFIX;
    String body = '{"q":"' + searchPrefix + ':' + globalPartyId + '"}';
    request.setBody(body);
    System.debug('requestBody---' + body);
    Http http = new Http();
    HTTPResponse httpResponse = http.send(request);
    return httpResponse;
  }
  private static string getGlobalPartyId(string salesforceId) {
    string query = '', globalPartyId;
    if (salesforceId.startsWith(CONTACTID_PREFIX)) {
      Contact contact = [
        SELECT GlobalPartyId
        FROM Contact
        WHERE id = :salesforceId
      ];
      globalPartyId = contact.GlobalPartyId;
    } else if (salesforceId.startsWith(LEADID_PREFIX)) {
      Lead lead = [SELECT GlobalPartyId FROM Lead WHERE id = :salesforceId];
      globalPartyId = lead.GlobalPartyId;
    }
    system.debug('get globalparty id ' + globalPartyId);
    return globalPartyId;
  }
  private static Customer360SearchModels.Address buidlAddressContactPoint(
    Customer360SearchModels.AddressContactPoint nodeData
  ) {
    Customer360SearchModels.Address addressObj = new Customer360SearchModels.Address();
    addressObj.addressLine1 = nodeData.addressLine1;
    addressObj.addressLine2 = nodeData.addressLine2;
    addressObj.cityName = nodeData.cityName;
    addressObj.postalCode = nodeData.postalCode;
    addressObj.stateProvinceCode = nodeData.stateProvinceCode;
    addressObj.stateProvinceName = nodeData.stateProvinceName;
    addressObj.countryName = nodeData.countryName;
    return addressObj;
  }

  @AuraEnabled
  public static string adoptContactDetails(string adoptDetailsJSON) {
    String response = '';
    System.debug('adoptDetailsJSON----' + adoptDetailsJSON);
    AdoptContactDetailWrapper adoptDetailsWrapper = (AdoptContactDetailWrapper) JSON.deserialize(
      adoptDetailsJSON,
      AdoptContactDetailWrapper.class
    );
    System.debug('adoptDetailsWrapper----' + adoptDetailsWrapper);
    //  System.debug('email values--'+ adoptDetailsWrapper.adoptedEmailValues.contactPointValue);
    if (adoptDetailsWrapper.sObjectName == CONTACT_SOBJECT) {
      Contact contactRec = new Contact(Id = adoptDetailsWrapper.recordID);
      if (
        adoptDetailsWrapper.adoptedEmailValues != null &&
        adoptDetailsWrapper.adoptedEmailValues.contactPointValue != null
      ) {
        contactRec.Email = adoptDetailsWrapper.adoptedEmailValues.contactPointValue;
      }
      if (
        adoptDetailsWrapper.adoptedPhoneValues != null &&
        adoptDetailsWrapper.adoptedPhoneValues.contactPointValue != null
      ) {
        if (
          adoptDetailsWrapper.adoptedPhoneValues.contactPointType ==
          CONTACT_TYPE_NAME_PHONE
        ) {
          contactRec.Phone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;
        }
        if (
          adoptDetailsWrapper.adoptedPhoneValues.contactPointType ==
          CONTACT_TYPE_NAME_MOBILE
        ) {
          contactRec.MobilePhone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;
        }
      }
      if (
        adoptDetailsWrapper.adoptedAddressValues != null &&
        adoptDetailsWrapper.adoptedAddressValues.addressLine1 != null
      ) {
        contactRec.MailingStreet = adoptDetailsWrapper.adoptedAddressValues.addressLine1;
        contactRec.MailingCity = adoptDetailsWrapper.adoptedAddressValues.cityName;
        contactRec.MailingCountry = adoptDetailsWrapper.adoptedAddressValues.countryName;
        contactRec.MailingState = adoptDetailsWrapper.adoptedAddressValues.stateProvinceName;
        //contactRec.MailingStateCode = adoptDetailsWrapper.adoptedAddressValues.stateProvinceCode;
        contactRec.MailingPostalCode = adoptDetailsWrapper.adoptedAddressValues.postalCode;
      }
      try {
        // Added on 12 Jan 2022 for skip Duplicate Rule --------
        // @doc: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Database_DMLOptions_DuplicateRuleHeader.htm
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.update(contactRec, dml);
        /* --------------------------------------------------------------*/
        response = SUCCESS_STATUS;
        // Added on 08 Sep, 2021
        Logger.info(
          'Adopt contact updated successfully. CONTACT_RECORD_ID: ' +
          contactRec.Id
        );
        Logger.saveLog();
      } catch (Exception ex) {
        response = 'Error - ' + ex.getMessage();
        // Added on 08 Sep, 2021
        Logger.error(
          'Adopt contact updation is failed. ERROR: ' + ex.getMessage()
        );
        Logger.saveLog();
      }
    }
    if (adoptDetailsWrapper.sObjectName == LEAD_SOBJECT) {
      Lead leadRec = new Lead(Id = adoptDetailsWrapper.recordID);
      if (
        adoptDetailsWrapper.adoptedEmailValues != null &&
        adoptDetailsWrapper.adoptedEmailValues.contactPointValue != null
      ) {
        leadRec.Email = adoptDetailsWrapper.adoptedEmailValues.contactPointValue;
      }
      if (
        adoptDetailsWrapper.adoptedPhoneValues != null &&
        adoptDetailsWrapper.adoptedPhoneValues.contactPointValue != null
      ) {
        if (
          adoptDetailsWrapper.adoptedPhoneValues.contactPointType ==
          CONTACT_TYPE_NAME_PHONE
        ) {
          leadRec.Phone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;
        }
        if (
          adoptDetailsWrapper.adoptedPhoneValues.contactPointType ==
          CONTACT_TYPE_NAME_MOBILE
        ) {
          leadRec.MobilePhone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;
        }
      }
      if (
        adoptDetailsWrapper.adoptedAddressValues != null &&
        adoptDetailsWrapper.adoptedAddressValues.addressLine1 != null
      ) {
        leadRec.Street = adoptDetailsWrapper.adoptedAddressValues.addressLine1;
        leadRec.City = adoptDetailsWrapper.adoptedAddressValues.cityName;
        leadRec.StateCode = adoptDetailsWrapper.adoptedAddressValues.stateProvinceCode;
        leadRec.Country = adoptDetailsWrapper.adoptedAddressValues.countryName;
        leadRec.PostalCode = adoptDetailsWrapper.adoptedAddressValues.postalCode;
      }
      try {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.update(leadRec, dml);
        response = SUCCESS_STATUS;
        // Added on 08 Sep, 2021
        Logger.info(
          'Adopt Lead updated successfully. LEAD_RECORD_ID: ' + leadRec.Id
        );
        Logger.saveLog();
      } catch (Exception ex) {
        response = ERROR_STATUS + ' - ' + ex.getMessage();
        // Added on 08 Sep, 2021
        Logger.error(
          'Adopt Lead updation is failed. ERROR: ' + ex.getMessage()
        );
        Logger.saveLog();
      }
    }
    return response;
  }

  public class AdoptContactDetailWrapper {
    @AuraEnabled
    public string recordID;
    @AuraEnabled
    public string sObjectName;
    @AuraEnabled
    public contactPointResponse adoptedEmailValues;
    @AuraEnabled
    public contactPointResponse adoptedPhoneValues;
    @AuraEnabled
    public addressPointResponse adoptedAddressValues;
    @AuraEnabled
    public contactPointResponse adoptedPartyIdentificationValues;
  }

  public class contactPointResponse {
    @AuraEnabled
    public string contactPointValue;
    @AuraEnabled
    public string contactPointType;
    @AuraEnabled
    public string dataSourceName;
  }

  public class addressPointResponse {
    @AuraEnabled
    public string addressLine1;
    @AuraEnabled
    public string addressLine2;
    @AuraEnabled
    public string cityName;
    @AuraEnabled
    public string stateProvinceCode;
    @AuraEnabled
    public string stateProvinceName;
    @AuraEnabled
    public string countryName;
    @AuraEnabled
    public string postalCode;
    @AuraEnabled
    public string dataSourceName;
    @AuraEnabled
    public String MailingState;
    @AuraEnabled
    public String MailingStateCode;
  }

  public class globalProfileFinalResponse {
    @AuraEnabled
    public string firstName { get; set; }
    @AuraEnabled
    public string lastName { get; set; }
    @AuraEnabled
    public string globalPartyId { get; set; }
    @AuraEnabled
    public string dataSourceRecordId { get; set; }
    @AuraEnabled
    public list<contactPointResponse> EmailContactPoints { get; set; }
    @AuraEnabled
    public list<contactPointResponse> PhoneContactPoints { get; set; }
    @AuraEnabled
    public list<addressPointResponse> AddressContactPoints { get; set; }
    @AuraEnabled
    public list<contactPointResponse> PartyIdentificationContactPoints {
      get;
      set;
    }
    @AuraEnabled
    public string errorMessage { get; set; }
    @AuraEnabled
    public string status { get; set; }
  }
}
