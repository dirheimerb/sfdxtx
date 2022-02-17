/*
@description       : 
@author            : Kalyani Jagdale
@group             : 
@last modified on  : 07-10-2021
@last modified by  : Kalyani Jagdale
Modifications Log 
Ver   Date         Author       Modification
1.0   06-015-2021   Kalyani Jagdale   Initial Version 
*/

public with sharing class GlobalSearchBeforeCreateController {
  private static final boolean enableLogging = true; // todo: make configurable

  private static final string CONTACTID_PREFIX = '003';
  private static final string LEADID_PREFIX = '00Q';
  private static final string LEAD_OBJECT_NAME = 'Lead';
  private static final string CONTACT_OBJECT_NAME = 'Contact';
  private static final string PHONE_SEARCH_PREFIX = 'phoneNumber';
  private static final string EMAIL_SEARCH_PREFIX = 'emailaddress';
  private static final string GLOBALPARTYID_SEARCH_PREFIX = 'globalPartyId';
  private static final string SFSC_LOCAL_ID_SEARCH_PREFIX = 'sfscLocalId';

  private static string SALESCLOUD_NAME = Customer_360_DM__mdt.getInstance(
      'C360_Global_Search'
    )
    .C360_Salescloud_Org__c;
  private static string SFDC_DOMAIN = Customer_360_DM__mdt.getInstance(
      'C360_Global_Search'
    )
    .C360_SFDC_Domain__c;

  private static string GLOBAL360_API_ENDPOINT = Customer_360_DM__mdt.getInstance(
      'C360_Global_Search'
    )
    .C360_Global360_Api_Endpoint__c;
  private static final integer GLOBAL360_API_REQUEST_TIMEOUT = Integer.valueOf(
    Customer_360_DM__mdt.getInstance('C360_Global_Search').C360_Timeout_value__c
  );

  @AuraEnabled
  public static Customer360SearchModels.Global360DataWrapper searchGlobalData(
    String searchExpression
  ) {
    log(
      'EXECUTION START: ' +
      DateTime.now().format('MMMMM dd, yyyy hh:mm:ss:SSS a')
    );
    log('INPUT SEARCH EXPRESSION: ' + searchExpression);

    // call the C360 API and get a response
    Customer360SearchModels.Global360DataWrapper customer360Data = getCustomer360Data(
      searchExpression
    );

    log(
      'FINAL RESPONSE --> SEARCH EXPRESSION: ' +
      searchExpression +
      '; RESPONSE: ' +
      customer360Data
    );
    log(
      'EXECUTION END: ' + DateTime.now().format('MMMMM dd, yyyy hh:mm:ss:SSS a')
    );

    return customer360Data;
  }

  public static Customer360SearchModels.Global360DataWrapper getCustomer360Data(
    String searchExpression
  ) {
    Customer360SearchModels.Global360DataWrapper customer360ResponseWrapper = new Customer360SearchModels.Global360DataWrapper();

    try {
      // detect prefix from the input search expression
      String searchPrefix = getSearchPrefix(searchExpression);

      // call the customer360 API based on the input search expression and get a response
      Customer360SearchModels.Customer360GlobalProfileResponse c360Response = getCustomer360ApiResponse(
        searchExpression,
        searchPrefix
      );

      List<Customer360SearchModels.GlobalProfileFinalResponse> globalProfileData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

      // parse the C360 API response
      system.debug('*** c360Response ' + c360Response);
      globalProfileData = buildFinalResponseList(c360Response);

      // append local leads and contacts (Salesforce local database) in the response
      appendLocalProfileDataInResponse(
        globalProfileData,
        searchExpression,
        searchPrefix
      );
      //Response of global profile
      customer360ResponseWrapper.globalProfileData = globalProfileData;

      Logger.info('Customer 360 response successfully received.');
      Logger.saveLog();
    } catch (Exception ex) {
      log(
        'AN ERROR OCCURED --> SEARCH EXPRESSION: ' +
        searchExpression +
        '; EXCEPTION: ' +
        ex.getStackTraceString()
      );

      // set the exception message in the response
      customer360ResponseWrapper.exceptionMessage = ex.getMessage();

      // Added on 08 Sep, 2021
      Logger.error(
        'Customer 360 response not received. ERROR: ' + ex.getMessage()
      );
      Logger.saveLog();
    }

    return customer360ResponseWrapper;
  }

  @AuraEnabled
  public static Customer360SearchModels.Customer360GlobalProfileResponse getCustomer360ApiResponse(
    string searchExpression,
    string searchPrefix
  ) {
    HttpRequest request = new HttpRequest();

    String body = getSearchRequestBody(searchExpression);

    request.setEndpoint(GLOBAL360_API_ENDPOINT);
    request.setHeader('x-sfdc-domain', SFDC_DOMAIN);
    request.setHeader('Content-Type', 'application/json');
    request.setMethod('POST');
    request.setBody(body);
    request.setTimeout(GLOBAL360_API_REQUEST_TIMEOUT);

    Http http = new Http();
    log('** request body: ' + body);
    HTTPResponse httpResponse = http.send(request);
    string response = httpResponse.getBody();
    log('** response body: ' + response);

    Customer360SearchModels.Customer360GlobalProfileResponse c360Response = (Customer360SearchModels.Customer360GlobalProfileResponse) JSON.deserialize(
      response,
      Customer360SearchModels.Customer360GlobalProfileResponse.class
    );

    return c360Response;
  }
  private static void appendLocalProfileDataInResponse(
    List<Customer360SearchModels.GlobalProfileFinalResponse> response,
    string searchExpression,
    string searchPrefix
  ) {
    // check leads and contacts locally
    /*List<Contact> contacts = getLocalContacts(searchExpression, searchPrefix);
     List<Lead> leads = getLocalLeads(searchExpression, searchPrefix);*/
    List<Contact> contacts = new List<Contact>();
    List<Lead> leads = new List<Lead>();
    if (
      searchPrefix == EMAIL_SEARCH_PREFIX ||
      searchPrefix == PHONE_SEARCH_PREFIX
    ) {
      if (searchPrefix == PHONE_SEARCH_PREFIX) {
        searchExpression = searchExpression.replaceAll('[^0-9]', '');
      }
      List<List<SObject>> sobjList = getLocalRecordsForEmailAndPhone(
        searchExpression
      );
      contacts = sobjList[0];
      leads = sobjList[1];
      system.debug('*** local records contacts ' + contacts);
      system.debug('*** local records leads ' + leads);
    } else if (searchPrefix == SFSC_LOCAL_ID_SEARCH_PREFIX) {
      if (searchExpression.startsWith(CONTACTID_PREFIX)) {
        contacts = getLocalContactRecordForId(searchExpression);
        system.debug('*** contacts ' + contacts);
      } else if (searchExpression.startsWith(LEADID_PREFIX)) {
        leads = getLocalLeadRecordForId(searchExpression);
        system.debug('*** leads ' + leads);
      }
    }

    appendLocalContactsToResponse(response, contacts);
    appendLocalLeadsToResponse(response, leads);
  }

  //get request body
  private static string getSearchRequestBody(String searchExpression) {
    String globalPartyIdRegex = '.*?-gpid-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';
    Boolean globalPartyIdFlag = Pattern.matches(
      globalPartyIdRegex,
      searchExpression
    );

    string searchPrefix = getSearchPrefix(searchExpression);
    if (searchPrefix == 'phoneNumber') {
      String characterRegex = '/[^a-zA-Z0-9]/g';
      searchExpression = searchExpression.replace(characterRegex, '');
    } else if (searchPrefix == 'globalPartyId' && !globalPartyIdFlag) {
      searchExpression = getGlobalPartyId(searchExpression);
    }

    String body = '{"q":"' + searchPrefix + ':' + searchExpression + '"}';
    system.debug('*** body ' + body);
    return body;
  }

  private static void parsePartyIdentifications(
    Customer360SearchModels.Customer360globalProfile c360Response,
    Customer360SearchModels.GlobalProfileFinalResponse parsedResponse
  ) {
    // parse party identification node
    List<Customer360SearchModels.PartyIdentification> partyIdentifications = new List<Customer360SearchModels.PartyIdentification>();

    List<Customer360SearchModels.PartyIdentification> partyIdentificationData = c360Response.Individual.partyIdentification;
    if (partyIdentificationData != null) {
      for (Integer j = 0; j < partyIdentificationData?.size(); j++) {
        Customer360SearchModels.PartyIdentification partyIdentification = buildPartyIdentificationData(
          partyIdentificationData[j]
        );
        partyIdentifications.add(partyIdentification);
      }
    }

    // sort the parsed party identifications and add to the response
    sortPartyIdentifications(partyIdentifications);
    parsedResponse.partyIdentifications = partyIdentifications;
  }

  private static void parseContactPoints(
    Customer360SearchModels.Customer360globalProfile c360Response,
    Customer360SearchModels.GlobalProfileFinalResponse parsedResponse
  ) {
    List<Customer360SearchModels.ContactPoint> contactPointsData = c360Response.Individual.contactPoints;

    List<Customer360SearchModels.EmailAddress> emailAddresses = new List<Customer360SearchModels.EmailAddress>();
    List<Customer360SearchModels.PhoneNumber> phoneNumbers = new List<Customer360SearchModels.PhoneNumber>();
    List<Customer360SearchModels.Address> fullAddresses = new List<Customer360SearchModels.Address>();

    for (integer j = 0; j < contactPointsData?.size(); j++) {
      String contactPointTypeName = contactPointsData[j].contactPointTypeName;

      // parse emails
      String emailAddressName = '', contactPointLastUpdatedEmailAddress = '';
      if (contactPointsData[j]?.emailContactPoint != null) {
        if (contactPointTypeName == 'Email') {
          Customer360SearchModels.EmailAddress emailAddress = buildEmailContactPoint(
            contactPointsData[j].emailContactPoint
          );
          emailAddresses.add(emailAddress);
        }
      }

      // parse phone numbers
      String phoneType;
      String extensionNumber,
        contactPointLastUpdatedDatePhoneNumbers,
        telephoneNumber,
        phoneCountryCode;
      if (contactPointsData[j]?.phoneContactPoint != null) {
        if (contactPointTypeName == 'Phone') {
          Customer360SearchModels.PhoneNumber phoneNumber = buildPhoneContactPoint(
            contactPointsData[j].phoneContactPoint
          );
          phoneNumbers.add(phoneNumber);
        }
      }

      // parse addresses
      String concatinatedAddress = '';
      String cityName,
        postalCode,
        stateProvinceCode,
        countryName,
        addressLine1,
        addressLine2,
        addressLine3,
        addressLine4;
      if (contactPointsData[j]?.addressContactPoint != null) {
        if (contactPointTypeName == 'Address') {
          Customer360SearchModels.Address fullAddress = buidlAddressContactPoint(
            contactPointsData[j].addressContactPoint
          );
          fullAddresses.add(fullAddress);
        }
      }
    }

    // sort the contact points in ascending order and add to the response
    sortEmailAddresses(emailAddresses);
    parsedResponse.contactPointEmails = emailAddresses;

    sortPhoneNumbers(phoneNumbers);
    parsedResponse.phoneNumbers = phoneNumbers;

    sortAddresses(fullAddresses);
    parsedResponse.fullAddress = fullAddresses;
  }

  private static void parseDataSources(
    Customer360SearchModels.Customer360globalProfile c360Response,
    Customer360SearchModels.GlobalProfileFinalResponse parsedResponse
  ) {
    // indicates if the C360 response has non-sales cloud contacts
    boolean hasNonSalesCloudContactData = false;

    String dataSources = '', objectName = ''; // '~~' seperated names
    List<String> dataSourceObjectNames = new List<String>();
    List<String> dataSourceRecordIds = new List<String>();

    List<Customer360SearchModels.DataSourcePoint> dataSourcePoints = new List<Customer360SearchModels.DataSourcePoint>();
    string dataSourceObjectName, dataSourceName, dataSourceRecordId;

    // iterate over audit records
    for (integer j = 0; j < c360Response?.AuditRecords?.size(); j++) {
      // parse audit records
      Customer360SearchModels.AuditRecords auditRecord = c360Response.AuditRecords[
        j
      ];
      List<Customer360SearchModels.DataSourceLineage> dataSourceLineageData = auditRecord.DataSourceLineage;

      // iterate over data source lineages
      for (integer k = 0; k < dataSourceLineageData?.size(); k++) {
        Customer360SearchModels.DataSourceLineage dataSourceLineage = dataSourceLineageData[
          k
        ];
        Customer360SearchModels.DataSourcePoint dataSourcePoint = new Customer360SearchModels.DataSourcePoint();

        //to display data sources and source record id on search results
        dataSources += dataSourceLineage.dataSourceName + '~~';
        objectName += dataSourceLineage.sourceObjectName + '~~';

        // to check the access for the data source records
        if (dataSourceLineage.dataSourceName == SALESCLOUD_NAME) {
          // salesforce data source
          dataSourceRecordId = dataSourceLineage.sourceRecordID;
          dataSourceObjectName = dataSourceLineage.sourceObjectName;
          dataSourceName = dataSourceLineage.dataSourceName;
          dataSourceObjectNames.add(dataSourceObjectName);

          // build a dataSourcePoint instance with appropriate flags checking the current user's access to the record
          dataSourcePoint = checkUsersAccessToRecord(
            dataSourceRecordId,
            dataSourceObjectName,
            dataSourceName,
            parsedResponse,
            hasNonSalesCloudContactData
          );
          dataSourcePoints.add(dataSourcePoint);
        } else {
          // non-salesforce data source
          dataSourceRecordId = dataSourceLineage.sourceRecordID;
          dataSourceObjectName = dataSourceLineage.sourceObjectName;
          dataSourceObjectNames.add(dataSourceObjectName);

          dataSourcePoint.dataSourcerecordId = dataSourceRecordId;
          if (objectName == 'Lead~~') {
            // marketing cloud data is only for a lead
            parsedResponse.canCreateContact = false;
            dataSourcePoint.isSalesforceRecord = false;
          } else {
            // marketing cloud data is for both contact and lead
            parsedResponse.canCreateContact = true;
            hasNonSalesCloudContactData = true;
            dataSourcePoint.isSalesforceRecord = false;
          }
          dataSourcePoints.add(dataSourcePoint);
        }
      }
    }

    parsedResponse.dataSources = dataSources.substringBeforeLast('~~');
    parsedResponse.datasourceObjectNames = dataSourceObjectNames;
    parsedResponse.dataSourcePoints = dataSourcePoints;
  }
  public static List<Customer360SearchModels.GlobalProfileFinalResponse> buildFinalResponseList(
    Customer360SearchModels.Customer360GlobalProfileResponse c360Response
  ) {
    // list of response data after parsing the C360 API response
    List<Customer360SearchModels.GlobalProfileFinalResponse> finalResponse = new List<Customer360SearchModels.GlobalProfileFinalResponse>();

    // iterate over results array
    for (integer i = 0; i < c360Response.results.size(); i++) {
      Customer360SearchModels.Customer360globalProfile currentResponse = c360Response.results[
        i
      ];

      // instance for building the final response
      Customer360SearchModels.GlobalProfileFinalResponse parsedResponse = new Customer360SearchModels.GlobalProfileFinalResponse();
      parsedResponse.canCreatecontact = true; // default value
      parsedResponse.isGlobalRecord = true; // default value indicating a synced record
      // parse individual
      parsedResponse.firstName = currentResponse.Individual?.firstName;
      parsedResponse.lastName = currentResponse.Individual?.lastName;
      parsedResponse.globalPartyId = currentResponse.Individual?.globalPartyId;

      // parse data sources
      parseDataSources(currentResponse, parsedResponse);

      // parse contact points
      parseContactPoints(currentResponse, parsedResponse);

      // parse party identifications
      parsePartyIdentifications(currentResponse, parsedResponse);

      finalResponse.add(parsedResponse);
    }

    return finalResponse;
  }
  private static void sortAddresses(
    list<Customer360SearchModels.Address> addresses
  ) {
    // sort the addresses based upon last updated date
    for (integer i = 0; i < addresses?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < addresses?.size(); j++) {
        if (
          addresses[j].contactPointLastUpdatedDate >
          addresses[min].contactPointLastUpdatedDate
        ) {
          Customer360SearchModels.Address temp = addresses[min];
          addresses[min] = addresses[j];
          addresses[j] = temp;
        }
      }
    }
  }

  private static void sortPhoneNumbers(
    list<Customer360SearchModels.PhoneNumber> phoneNumbers
  ) {
    // sort the phone numbers based upon last updated date
    for (integer i = 0; i < phoneNumbers?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < phoneNumbers?.size(); j++) {
        if (
          phoneNumbers[j].contactPointLastUpdatedDate >
          phoneNumbers[min].contactPointLastUpdatedDate
        ) {
          Customer360SearchModels.PhoneNumber temp = phoneNumbers[min];
          phoneNumbers[min] = phoneNumbers[j];
          phoneNumbers[j] = temp;
        }
      }
    }
  }

  private static void sortEmailAddresses(
    list<Customer360SearchModels.EmailAddress> emailAddresses
  ) {
    // sort the emails based upon last updated date
    for (integer i = 0; i < emailAddresses?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < emailAddresses?.size(); j++) {
        if (
          emailAddresses[j].contactPointLastUpdatedDate >
          emailAddresses[min].contactPointLastUpdatedDate
        ) {
          Customer360SearchModels.EmailAddress temp = emailAddresses[min];
          emailAddresses[min] = emailAddresses[j];
          emailAddresses[j] = temp;
        }
      }
    }
  }

  private static void sortPartyIdentifications(
    list<Customer360SearchModels.PartyIdentification> partyIdentifications
  ) {
    // sort the party identifications based upon last updated date
    for (integer i = 0; i < partyIdentifications?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < partyIdentifications?.size(); j++) {
        if (
          partyIdentifications[j].contactPointLastUpdatedDate >
          partyIdentifications[min].contactPointLastUpdatedDate
        ) {
          Customer360SearchModels.PartyIdentification temp = partyIdentifications[
            min
          ];
          partyIdentifications[min] = partyIdentifications[j];
          partyIdentifications[j] = temp;
        }
      }
    }
  }

  private static Customer360SearchModels.DataSourcePoint checkUsersAccessToRecord(
    id dataSourceRecordId,
    string dataSourceObjectName,
    string dataSourceName,
    Customer360SearchModels.GlobalProfileFinalResponse responseObj,
    Boolean hasNonSalesCloudContactData
  ) {
    Boolean canCreateContact;
    Customer360SearchModels.DataSourcePoint dataSourcePoint = new Customer360SearchModels.dataSourcePoint();
    //Check record access
    UserRecordAccess userAccess = new UserRecordAccess();
    if (
      dataSourceName == (SALESCLOUD_NAME) &&
      (dataSourceObjectName == CONTACT_OBJECT_NAME ||
      dataSourceObjectName == LEAD_OBJECT_NAME)
    ) {
      system.debug('** user id ' + userInfo.getUserId());
      userAccess = [
        SELECT RecordId, HasReadAccess
        FROM UserRecordAccess
        WHERE UserId = :userInfo.getUserId() AND RecordId = :dataSourceRecordId
        LIMIT 1
      ];
      system.debug('** user access ' + userAccess);
    }
    log('** DATASOURCE OBJECT NAME ' + dataSourceObjectName);
    log('** DATASOURCE NAME ' + dataSourceName);
    log('** DATASOURCE Id ' + dataSourceRecordId);
    system.debug('** user access ' + userAccess);

    // populate the dataSourcePoint instance based on user's access
    if (userAccess.HasReadAccess) {
      responseObj.canCreatecontact =
        (responseObj.canCreatecontact && false) || hasNonSalesCloudContactData;
      dataSourcePoint.isSalesforceRecord = true;
      dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
      String recordLabel = setContactLeadDetailsLabel(
        dataSourcePoint.dataSourcerecordId,
        dataSourcePoint.isSalesforceRecord
      );
      dataSourcePoint.recordLabel = recordLabel;
    } else if (
      !userAccess.HasReadAccess &&
      dataSourceObjectName.contains(LEAD_OBJECT_NAME)
    ) {
      responseObj.canCreateContact =
        (responseObj.canCreatecontact && true) || hasNonSalesCloudContactData;
      dataSourcePoint.isSalesforceRecord = false;
      dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
    } else if (
      !userAccess.HasReadAccess &&
      dataSourceObjectName.contains(CONTACT_OBJECT_NAME)
    ) {
      system.debug('** INSIDE CCONTACT OBJECT NAME');
      responseObj.canCreateContact =
        (responseObj.canCreatecontact && true) || hasNonSalesCloudContactData;
      dataSourcePoint.isSalesforceRecord = false;
      dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
    }

    return dataSourcePoint;
  }
  public static string setContactLeadDetailsLabel(
    String dataSourceRecordId,
    Boolean isSalesforceRecord
  ) {
    String recordLabel;
    if (
      isSalesforceRecord == true &&
      dataSourceRecordId.startsWith(CONTACTID_PREFIX)
    ) {
      recordLabel = 'Contact Details';
    } else if (
      isSalesforceRecord == true && dataSourceRecordId.startsWith(LEADID_PREFIX)
    ) {
      recordLabel = 'Lead Details';
    }
    return recordLabel;
  }

  private static Customer360SearchModels.EmailAddress buildEmailContactPoint(
    Customer360SearchModels.EmailContactPoint nodeData
  ) {
    String emailAddressName = nodeData.emailAddress;
    String contactPointLastUpdatedEmailAddress = nodeData.contactPointBase.contactPointLastUpdatedDate;

    Customer360SearchModels.EmailAddress emailAddressObj = new Customer360SearchModels.EmailAddress();
    emailAddressObj.emailAddressName = emailAddressName;
    emailAddressObj.contactPointLastUpdatedDate = Datetime.newInstance(
      long.valueOf(contactPointLastUpdatedEmailAddress)
    );

    return emailAddressObj;
  }

  private static Customer360SearchModels.PhoneNumber buildPhoneContactPoint(
    Customer360SearchModels.PhoneContactPoint nodeData
  ) {
    String phoneType,
      extensionNumber,
      contactPointLastUpdatedDatePhoneNumbers,
      telephoneNumber,
      phoneCountryCode,
      formattedInternationalPhoneNumber;

    phoneType = nodeData.phoneType;
    extensionNumber = nodeData.extensionNumber;
    contactPointLastUpdatedDatePhoneNumbers = nodeData.contactPointBase.contactPointLastUpdatedDate;
    phoneCountryCode = nodeData.phoneCountryCode;
    telephoneNumber = nodeData.formattedE164PhoneNumber;
    formattedInternationalPhoneNumber = nodeData.formattedInternationalPhoneNumber;

    Customer360SearchModels.PhoneNumber phoneNumberObj = new Customer360SearchModels.PhoneNumber();
    phoneNumberObj.telephoneNumber = telephoneNumber;
    phoneNumberObj.phoneCountryCode = phoneCountryCode;
    phoneNumberObj.contactType = phoneType;
    if (nodeData.phoneType.toLowerCase() == 'home') {
      phoneNumberObj.isContactType = true;
    }
    if (nodeData.phoneType.toLowerCase() == 'mobile') {
      phoneNumberObj.isContactType = false;
    }
    phoneNumberObj.extensionNumber = extensionNumber;
    phoneNumberObj.contactPointLastUpdatedDate = Datetime.newInstance(
      long.valueOf(contactPointLastUpdatedDatePhoneNumbers)
    );
    phoneNumberObj.formattedInternationalPhoneNumber = formattedInternationalPhoneNumber;

    return phoneNumberObj;
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
    addressObj.countryName = nodeData.countryName;
    addressObj.stateProvinceName = nodeData.stateProvinceName;
    String contactPointLastUpdatedAddressDate = nodeData.contactPointBase.contactPointLastUpdatedDate;
    addressObj.contactPointLastUpdatedDate = Datetime.newInstance(
      long.valueOf(contactPointLastUpdatedAddressDate)
    );

    return addressObj;
  }

  private static Customer360SearchModels.PartyIdentification buildPartyIdentificationData(
    Customer360SearchModels.PartyIdentification nodeData
  ) {
    Customer360SearchModels.PartyIdentification partyIdentificationObj = new Customer360SearchModels.PartyIdentification();
    partyIdentificationObj.identificationNumber = nodeData.identificationNumber;
    partyIdentificationObj.identifierName = nodeData.identifierName;

    String contactPointLastUpdatedIdentificationDate = nodeData.contactPointLastUpdatedDate;
    partyIdentificationObj.contactPointLastUpdatedDatePartyId = Datetime.newInstance(
      long.valueOf(contactPointLastUpdatedIdentificationDate)
    );

    return partyIdentificationObj;
  }

  //get search prefix key
  private static string getSearchPrefix(String searchExpression) {
    String searchPrefix = '';

    String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}[\\.\\w]*$';
    //String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+[\\.\\w]+$';

    // String phoneRegex = '[+]*(?:(\\+?\\d{1,3}) )?(?:([\\(]?\\d+[\\)]?)[\\s\\-\\.]?)?(\\d{1,5}[\\-\\s\\.]?\\d{1,5})';
    string phoneRegex = '[+]*[0-9\\s\\(\\)extension\\.\\-]+';
    String globalPartyIdRegex = '.*?-gpid-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';

    Boolean emailMatchFlag = Pattern.matches(emailRegex, searchExpression);
    //Boolean phoneMatchFlag = Pattern.matches(phoneRegex, searchExpression);
    Boolean globalPartyIdFlag = Pattern.matches(
      globalPartyIdRegex,
      searchExpression
    );
    Boolean localIdFlag =
      searchExpression.startsWithIgnoreCase(CONTACTID_PREFIX) ||
      searchExpression.startsWithIgnoreCase(LEADID_PREFIX);

    if (emailMatchFlag) {
      searchPrefix = EMAIL_SEARCH_PREFIX;
    } else if (globalPartyIdFlag) {
      searchPrefix = GLOBALPARTYID_SEARCH_PREFIX;
    } else if (localIdFlag) {
      // either a contact or lead ID
      // get relevant global party ID from the Salesforce database
      system.debug('** inside SFSC id ');
      searchPrefix = SFSC_LOCAL_ID_SEARCH_PREFIX;
    } else {
      // phone number
      searchPrefix = PHONE_SEARCH_PREFIX;
    }
    system.debug(' *** searchPrefix' + searchPrefix);
    return searchPrefix;
  }
  public static string getGlobalPartyId(string salesforceId) {
    string query = '', globalPartyId;
    if (salesforceId.startsWith(CONTACTID_PREFIX)) {
      Contact contact = [
        SELECT id, GlobalPartyId
        FROM Contact
        WHERE id = :salesforceId
      ];
      globalPartyId = contact.GlobalPartyId;
    } else if (salesforceId.startsWith(LEADID_PREFIX)) {
      Lead lead = [SELECT id, GlobalPartyId FROM Lead WHERE id = :salesforceId];
      globalPartyId = lead.GlobalPartyId;
    }

    return globalPartyId;
  }

  private static List<List<SObject>> getLocalRecordsForEmailAndPhone(
    String searchExpression
  ) {
    List<List<Sobject>> sobjList = [
      FIND :searchExpression
      IN ALL FIELDS
      RETURNING
        Contact(
          Id,
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
          OtherStreet),
        Lead(
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
          StateCode)
    ];
    return sobjList;
  }

  private static List<SObject> getLocalContactRecordForId(
    String searchExpression
  ) {
    return [
      SELECT
        Id,
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
      WHERE ID = :searchExpression
    ];
  }

  private static List<SObject> getLocalLeadRecordForId(
    String searchExpression
  ) {
    return [
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
      WHERE ID = :searchExpression
    ];
  }
  public static void appendLocalContactsToResponse(
    List<Customer360SearchModels.GlobalProfileFinalResponse> c360ResponseList,
    List<Contact> dbContacts
  ) {
    // iterate over local contacts and set the 'isLocalRecord' if a contact is not present in the C360 API response
    for (Contact contact : dbContacts) {
      Boolean isLocalRecord = true;
      if (isLocalRecord) {
        for (
          Customer360SearchModels.GlobalProfileFinalResponse c360Response : c360ResponseList
        ) {
          if (isLocalRecord) {
            for (
              Integer i = 0; i < c360Response?.dataSourcePoints?.size(); i++
            ) {
              if (
                String.valueOf(contact.Id) ==
                c360Response.dataSourcePoints[i].dataSourceRecordId
              ) {
                isLocalRecord = false;
                break;
              }
            }
          }
        }
      }

      // add the contact in response if it's local (not present in C360 API response)
      // create a new instance and populate fields
      Customer360SearchModels.GlobalProfileFinalResponse localContact = new Customer360SearchModels.GlobalProfileFinalResponse();
      if (isLocalRecord) {
        // basic fields
        localContact.firstName = contact.FirstName;
        localContact.lastName = contact.LastName;
        localContact.dataSources = SALESCLOUD_NAME;

        // data sources
        localContact.dataSourcePoints = new List<Customer360SearchModels.DataSourcePoint>();
        Customer360SearchModels.DataSourcePoint dataSourcePoint = new Customer360SearchModels.DataSourcePoint();
        dataSourcePoint.dataSourcerecordId = contact.id;
        dataSourcePoint.isSalesforceRecord = true;
        String recordLabel = setContactLeadDetailsLabel(
          dataSourcePoint.dataSourcerecordId,
          dataSourcePoint.isSalesforceRecord
        );
        dataSourcePoint.recordLabel = recordLabel;
        localContact.dataSourcePoints.add(dataSourcePoint);

        // data source objects
        localContact.datasourceObjectNames = new List<String>();
        localContact.datasourceObjectNames.add(CONTACT_OBJECT_NAME);

        // phone numbers
        localContact.phoneNumbers = new List<Customer360SearchModels.PhoneNumber>();
        // mobile phones
        Customer360SearchModels.PhoneNumber mobilePhone = new Customer360SearchModels.PhoneNumber();
        if (contact.MobilePhone != null) {
          mobilePhone.telephoneNumber = contact.MobilePhone;
          mobilePhone.isContactType = false;
          localContact.phoneNumbers.add(mobilePhone);
        }

        // phones
        Customer360SearchModels.PhoneNumber phone = new Customer360SearchModels.PhoneNumber();
        if (contact.Phone != null) {
          phone.telephoneNumber = contact.Phone;
          phone.extensionNumber = contact.Extension__c;
          phone.isContactType = true;
          localContact.phoneNumbers.add(phone);
        }

        // emails
        localContact.contactPointEmails = new List<Customer360SearchModels.EmailAddress>();
        // primary emails
        Customer360SearchModels.EmailAddress primaryEmail = new Customer360SearchModels.EmailAddress();
        if (contact.Email != null) {
          primaryEmail.emailAddressName = contact.Email;
          localContact.contactPointEmails.add(primaryEmail);
        }

        // secondary emails
        Customer360SearchModels.EmailAddress secondaryEmail = new Customer360SearchModels.EmailAddress();
        if (contact.Secondary_Email__c != null) {
          secondaryEmail.emailAddressName = contact.Secondary_Email__c;
          localContact.contactPointEmails.add(secondaryEmail);
        }

        // mailing address
        localContact.fullAddress = new List<Customer360SearchModels.Address>();

        Customer360SearchModels.Address mailingAddress = new Customer360SearchModels.Address();
        mailingAddress.addressLine1 = contact.MailingStreet;
        mailingAddress.addressLine2 = contact.OtherStreet;
        mailingAddress.cityName = contact.MailingCity;
        mailingAddress.postalCode = contact.MailingPostalCode;
        mailingAddress.stateProvinceName = contact.MailingState;
        mailingAddress.stateProvinceCode = contact.MailingStateCode;
        mailingAddress.countryName = contact.MailingCountry;
        localContact.fullAddress.add(mailingAddress);

        // set 'isGlobalRecord' flag indicating the record is not synced yet
        localContact.isGlobalRecord = false;

        // add the local contact to the final reponse list
        c360ResponseList.add(localContact);
      }
    }
  }
  public static void appendLocalLeadsToResponse(
    List<Customer360SearchModels.GlobalProfileFinalResponse> c360ResponseList,
    List<Lead> dbLeads
  ) {
    // iterate over local leads and set the 'isLocalRecord' if a lead is not present in the C360 API response

    for (Lead lead : dbLeads) {
      Boolean isLocalRecord = true;
      if (isLocalRecord) {
        for (
          Customer360SearchModels.GlobalProfileFinalResponse globalResponse : c360ResponseList
        ) {
          if (isLocalRecord) {
            for (
              Integer i = 0; i < globalResponse?.dataSourcePoints?.size(); i++
            ) {
              if (
                string.valueOf(lead.Id) ==
                globalResponse.dataSourcePoints[i].dataSourceRecordId
              ) {
                isLocalRecord = false;
                break;
              }
            }
          }
        }
      }

      // add the lead in response if it's local (not present in C360 API response)
      Customer360SearchModels.GlobalProfileFinalResponse localLead = new Customer360SearchModels.GlobalProfileFinalResponse();
      if (isLocalRecord) {
        // basic fields
        localLead.firstName = lead.FirstName;
        localLead.lastName = lead.LastName;
        localLead.dataSources = SALESCLOUD_NAME;

        // data sources
        localLead.dataSourcePoints = new List<Customer360SearchModels.DataSourcePoint>();
        Customer360SearchModels.DataSourcePoint dataSourcePoint = new Customer360SearchModels.DataSourcePoint();
        dataSourcePoint.dataSourcerecordId = lead.id;
        dataSourcePoint.isSalesforceRecord = true;
        String recordLabel = setContactLeadDetailsLabel(
          dataSourcePoint.dataSourcerecordId,
          dataSourcePoint.isSalesforceRecord
        );
        dataSourcePoint.recordLabel = recordLabel;
        localLead.dataSourcePoints.add(dataSourcePoint);

        // data source objects
        localLead.datasourceObjectNames = new List<String>();
        localLead.datasourceObjectNames.add(LEAD_OBJECT_NAME);

        // phone numbers
        localLead.phoneNumbers = new List<Customer360SearchModels.PhoneNumber>();
        // mobile phones
        Customer360SearchModels.PhoneNumber mobilePhone = new Customer360SearchModels.PhoneNumber();
        if (lead.MobilePhone != null) {
          mobilePhone.telephoneNumber = lead.MobilePhone;
          mobilePhone.isContactType = false;
          localLead.phoneNumbers.add(mobilePhone);
        }

        // phones
        Customer360SearchModels.PhoneNumber phone = new Customer360SearchModels.PhoneNumber();
        if (lead.Phone != null) {
          phone.telephoneNumber = lead.Phone;
          phone.extensionNumber = lead.Extension__c;
          phone.isContactType = true;
          localLead.phoneNumbers.add(phone);
        }

        // emails
        localLead.contactPointEmails = new List<Customer360SearchModels.EmailAddress>();
        // primary emails
        Customer360SearchModels.EmailAddress primaryEmail = new Customer360SearchModels.EmailAddress();
        if (lead.Email != null) {
          primaryEmail.emailAddressName = lead.Email;
          localLead.contactPointEmails.add(primaryEmail);
        }

        // mailing address
        localLead.fullAddress = new List<Customer360SearchModels.Address>();

        Customer360SearchModels.Address mailingAddress = new Customer360SearchModels.Address();
        mailingAddress.addressLine1 = lead.Street;
        mailingAddress.cityName = lead.City;

        mailingAddress.postalCode = Lead.PostalCode;
        mailingAddress.stateProvinceName = lead.State;
        mailingAddress.stateProvinceCode = lead.StateCode;
        mailingAddress.countryName = lead.Country;
        localLead.fullAddress.add(mailingAddress);

        // set 'isGlobalRecord' flag indicating the record is not synced yet
        localLead.isGlobalRecord = false;

        // add the local lead to the final reponse list
        c360ResponseList.add(localLead);
      }
    }
  }
  private static void log(string msg) {
    if (enableLogging)
      system.debug(msg);
  }
}
