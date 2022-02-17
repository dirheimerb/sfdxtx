/**
* @description       : 
* @author            : Kalyani Jagdale
* @group             : 
* @last modified on  : 01/05/2022
* @last modified by  : Kalyani Jagdale
Modifications Log 
Ver   Date         Author       Modification
1.0   01-05-2021   Suseen   		   Initial Version  

**/

public with sharing class CDP_UnifiedProfileData {
  public static string testdata = '';
  private static final string CONTACTID_PREFIX = '003';
  private static final string LEADID_PREFIX = '00Q';
  private static String SALES_CLOUD_NAME = 'Sales Cloud';
  private static final string LEAD_OBJECT_NAME = 'Lead';
  private static final string CONTACT_OBJECT_NAME = 'Contact';
  private static final string PHONE_SEARCH_PREFIX = 'phoneNumber';
  private static final string EMAIL_SEARCH_PREFIX = 'emailaddress';
  private static final string SFSC_LOCAL_ID_SEARCH_PREFIX = 'sfscLocalId';
  private static final string EMAIL = 'EMAIL';
  private static final string SECONDARYEMAIL = 'SECONDARY EMAIL';
  private static final string MOBILEPHONE = 'MOBILE PHONE';
  private static final string PHONE = 'PHONE';
  private static final string ADDRESS = 'ADDRESS';
  private static final string PARTYID = 'PARTYID';
  private static string SALESCLOUD_NAME = CDP_Source_Name__mdt.getInstance(
      'Sales_Cloud'
    )
    .CDP_DataSource_Name__c;

  @AuraEnabled
  public static CDPSearchModels.UIFinalResponseWrapper getCDPResponse(
    String searchExpression,
    String searchType
  ) {
    try {
      CDPSearchModels.UIFinalResponseWrapper finalResponseList = new CDPSearchModels.UIFinalResponseWrapper();
      List<CDPSearchModels.UIFinalResponse> CDPFinalUIResponseList = new List<CDPSearchModels.UIFinalResponse>();
      CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse = new CDPSearchModels.CDPUnifiedProfileResponse();
      if (Test.isRunningTest()) {
        unifiedProfileResponse = (CDPSearchModels.CDPUnifiedProfileResponse) JSON.deserialize(
          testdata,
          CDPSearchModels.CDPUnifiedProfileResponse.class
        );
      } else {
        unifiedProfileResponse = CDP_APIUtls.getQueryAPIResponse(
          searchExpression,
          searchType
        );
      }

      system.debug(
        'unifiedProfileResponse**' + JSON.serialize(unifiedProfileResponse)
      );
      //metadata to map data source name
      Map<string, string> dataSourceNameMap = new Map<string, string>();
      dataSourceNameMap = getDataSourceName();

      system.debug('***** dataSourceNameMap ' + dataSourceNameMap);

      Integer responseSize = unifiedProfileResponse.data.size();
      List<String> UPIds = new List<String>();

      //List for filling UPIds
      UPIds = getUPID(responseSize, unifiedProfileResponse, UPIds);

      List<String> dataSourceOrgIds = new List<String>();
      List<String> dataSourceObjectNames = new List<String>();

      //initialize UPIds and dataSourceRecord Id map
      Map<String, List<String>> dataSourceRecordIdMap = new Map<String, List<String>>();
      dataSourceRecordIdMap = getDataSourceRecordId(
        UPIds,
        responseSize,
        unifiedProfileResponse,
        dataSourceOrgIds,
        dataSourceObjectNames,
        dataSourceRecordIdMap
      );

      for (String currentUPId : dataSourceRecordIdMap.keySet()) {
        CDPSearchModels.UIFinalResponse CDPDataUIResponse = new CDPSearchModels.UIFinalResponse();
        CDPDataUIResponse.dataSourcePoints = new List<CDPSearchModels.DataSourcePoint>();
        CDPDataUIResponse.contactPointEmails = new List<CDPSearchModels.EmailAddress>();
        CDPDataUIResponse.phoneNumbers = new List<CDPSearchModels.PhoneNumber>();
        CDPDataUIResponse.fullAddress = new List<CDPSearchModels.Address>();
        CDPDataUIResponse.partyIdentifications = new List<CDPSearchModels.PartyIdentification>();
        CDPDataUIResponse.datasourceObjectNames = new List<string>();
        CDPDataUIResponse.dataSources = '';
        CDPDataUIResponse.canCreatecontact = true; //default value to display create new button

        List<String> dataSourceRecordIds = dataSourceRecordIdMap.get(
          currentUPId
        );

        Integer dataSourceRecordIdListSize = dataSourceRecordIds.size();
        for (Integer i = 0; i < dataSourceRecordIdListSize; i++) {
          String currentDataSourceId = dataSourceRecordIds[i];
          // to display source record id
          CDPSearchModels.DataSourcePoint dataSourcePoint = new CDPSearchModels.DataSourcePoint();
          dataSourcePoint.dataSourcerecordId = currentDataSourceId;

          // to display data source object record names
          CDPDataUIResponse.datasourceObjectNames.add(dataSourceObjectNames[i]);

          for (Integer j = 0; j < responseSize; j++) {
            CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[
              j
            ];
            if (currentResponse.Id != currentUPId)
              continue;

            //to map UPID to response
            CDPDataUIResponse.UPId = currentResponse?.Id;

            List<string> sourceRecordData = currentResponse.SourceRecord.split(
              ','
            );
            String tempDataSourceId = sourceRecordData[2];
            string dataSourceName = sourceRecordData[1];
            string orgid = sourceRecordData[0];

            if (currentDataSourceId != tempDataSourceId)
              continue;
            /*if(sourceRecordData[2]=='0033Z00002NGUPaQAP'){
                            sourceRecordData[2] =  '0030100000J8ODlAAN';
                        }*/
            //sourceRecordData[2] =  '0030100000J8ODlAAN';
            if (dataSourceNameMap.get(orgid) == SALES_CLOUD_NAME) {
              dataSourcePoint = checkUsersAccessToRecord(
                sourceRecordData[2],
                sourceRecordData[1],
                dataSourceNameMap.get(orgid),
                CDPDataUIResponse,
                false
              );
              System.debug(
                'data access--' + CDPDataUIResponse.canCreateContact
              );
            }

            Set<String> sourceorg = new Set<String>();
            //display first name and last name - starts
            if (currentResponse.ContactPointType == 'INDIVIDUAL') {
              List<string> fullName = parseName(currentResponse);

              CDPDataUIResponse.firstName = fullName[0];
              if (fullName.size() > 1) {
                CDPDataUIResponse.lastName = fullName[1];
              }
            }
            //display first name and last name - ends

            // to display email
            if (currentResponse.ContactPointType == EMAIL) {
              parseEmailResponse(currentResponse, CDPDataUIResponse);
            } else if (currentResponse.ContactPointType == SECONDARYEMAIL) {
              parseEmailResponse(currentResponse, CDPDataUIResponse);
            } else if (currentResponse.ContactPointType == MOBILEPHONE) {
              // to display  mobile phone
              parsePhoneResponse(
                currentResponse,
                CDPDataUIResponse,
                'Mobile',
                false
              );
            } else if (currentResponse.ContactPointType == PHONE) {
              // to display phone
              parsePhoneResponse(
                currentResponse,
                CDPDataUIResponse,
                'Home',
                true
              );
            } else if (currentResponse.ContactPointType == ADDRESS) {
              // to display Address
              parseAddressResponse(currentResponse, CDPDataUIResponse);
            } else if (currentResponse.ContactPointType == PARTYID) {
              // to display party id
              parsePartyidResponse(currentResponse, CDPDataUIResponse);
            }
          }
          if (dataSourceNameMap.containsKey(dataSourceOrgIds[i])) {
            System.debug(
              'DataSourceName00--' + dataSourceNameMap.get(dataSourceOrgIds[i])
            );
            dataSourcePoint.dataSourceName = dataSourceNameMap.get(
              dataSourceOrgIds[i]
            );
            CDPDataUIResponse.dataSources +=
              dataSourceNameMap.get(dataSourceOrgIds[i]) + '~~';
          }
          CDPDataUIResponse.dataSourcePoints.add(dataSourcePoint);
        }
        CDPFinalUIResponseList.add(CDPDataUIResponse);
      }
      finalResponseList.unifiedProfileData = CDPFinalUIResponseList;

      // Added on 05 Jan, 2022
      Logger.info('CDP response received successfully.');
      Logger.saveLog();

      return finalResponseList;
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error(
        'CDP response not received, some error is coming. ERROR: ' +
        e.getMessage()
      );
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }

  //metadata method to get Data source name
  private static Map<String, String> getDataSourceName() {
    Map<string, string> dataSourceNameMap = new Map<string, string>();
    CDP_Source_Name__mdt[] SourceRecords = [
      SELECT MasterLabel, CDP_DataSource_Name__c, CDP_SourceID__c
      FROM CDP_Source_Name__mdt
    ];

    for (CDP_Source_Name__mdt record : SourceRecords) {
      dataSourceNameMap.put(
        record.CDP_SourceID__c,
        record.CDP_DataSource_Name__c
      );
    }
    return dataSourceNameMap;
  }

  //method to get parse firstName and lastName
  private static List<String> parseName(
    CDPSearchModels.CDPUnifiedProfile currentResponse
  ) {
    CDPSearchModels.UIFinalResponse CDPDataUIResponse = new CDPSearchModels.UIFinalResponse();
    List<String> fullName = currentResponse?.ContactPoint.split(',');
    return fullName;
  }

  //method to check whether sales user has access to record or not
  private static CDPSearchModels.DataSourcePoint checkUsersAccessToRecord(
    id dataSourceRecordId,
    string dataSourceObjectName,
    string dataSourceName,
    CDPSearchModels.UIFinalResponse responseObj,
    Boolean hasNonSalesCloudContactData
  ) {
    Boolean canCreateContact;
    CDPSearchModels.DataSourcePoint dataSourcePoint = new CDPSearchModels.dataSourcePoint();
    //Check record access
    UserRecordAccess userAccess = new UserRecordAccess();
    if (
      dataSourceName == (SALES_CLOUD_NAME) &&
      (dataSourceObjectName == CONTACT_OBJECT_NAME ||
      dataSourceObjectName == LEAD_OBJECT_NAME)
    ) {
      userAccess = [
        SELECT RecordId, HasReadAccess
        FROM UserRecordAccess
        WHERE UserId = :userInfo.getUserId() AND RecordId = :dataSourceRecordId
        LIMIT 1
      ];
    }
    dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
    // populate the dataSourcePoint instance based on user's access
    if (userAccess.HasReadAccess) {
      responseObj.canCreatecontact = false;
      dataSourcePoint.isSalesforceRecord = true;
    } else {
      dataSourcePoint.isSalesforceRecord = false;
    }
    return dataSourcePoint;
  }

  //method to get all UPIDs
  public static List<String> getUPID(
    Integer responseSize,
    CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse,
    List<String> UPIds
  ) {
    try {
      for (integer i = 0; i < responseSize; i++) {
        CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[
          i
        ];

        if (!UPIds.contains(currentResponse.Id)) {
          UPIds.add(currentResponse.Id);
        }
      }
      // Added on 05 Jan, 2022
      Logger.info('UPID generated successfully.');
      Logger.saveLog();
      return UPIds;
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error('UPID not generated. ERROR : ' + e.getMessage());
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }
  //method to parse Party id response - physician registration no
  public static void parsePartyidResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    CDPSearchModels.UIFinalResponse CDPDataUIResponse
  ) {
    try {
      CDPSearchModels.PartyIdentification partyIdentification = new CDPSearchModels.PartyIdentification();
      List<String> partyIdentifications = currentResponse
        ?.ContactPoint.split(',');

      partyIdentification.identifierName = partyIdentifications[0];
      if (partyIdentifications.size() > 1) {
        partyIdentification.identificationNumber = partyIdentifications[1];
      }
      system.debug('*** partyIdentifications135 ' + partyIdentification);

      CDPDataUIResponse.partyIdentifications.add(partyIdentification);
      sortPartyIdentifications(CDPDataUIResponse.partyIdentifications);
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error('Response parsing error. ' + e.getMessage());
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }
  //parse address response
  public static void parseAddressResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    CDPSearchModels.UIFinalResponse CDPDataUIResponse
  ) {
    try {
      CDPSearchModels.Address address = new CDPSearchModels.Address();
      List<String> fulladdress = currentResponse?.ContactPoint.split('~');
      address.addressLine1 = fulladdress[0];
      if (fulladdress.size() > 1) {
        address.cityName = fulladdress[1];
      }
      if (fulladdress.size() > 2) {
        address.stateProvinceName = fulladdress[2];
      }
      if (fulladdress.size() > 3) {
        address.postalCode = fulladdress[3];
      }
      if (fulladdress.size() > 4) {
        address.countryName = fulladdress[4];
      }
      CDPDataUIResponse.fullAddress.add(address);
      sortAddresses(CDPDataUIResponse.fullAddress);
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error('Response parsing error. ' + e.getMessage());
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }
  //parse mobile phone and phone
  public static void parsePhoneResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    CDPSearchModels.UIFinalResponse CDPDataUIResponse,
    String contactType,
    Boolean isContactType
  ) {
    try {
      CDPSearchModels.PhoneNumber phoneNumber = new CDPSearchModels.PhoneNumber();
      phoneNumber.telephoneNumber = currentResponse.ContactPoint;
      phoneNumber.contactPointLastUpdatedDate = DateTime.valueOf(
        currentResponse.LastModifiedDate
      );
      phoneNumber.isContactType = isContactType;
      phoneNumber.contactType = contactType;
      CDPDataUIResponse.phoneNumbers.add(phoneNumber);
      sortPhoneNumbers(CDPDataUIResponse.phoneNumbers);
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error('Response parsing error. ' + e.getMessage());
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }
  //parse email and secondary email
  public static void parseEmailResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    CDPSearchModels.UIFinalResponse CDPDataUIResponse
  ) {
    try {
      CDPSearchModels.EmailAddress email = new CDPSearchModels.EmailAddress();
      email.emailAddressName = currentResponse.ContactPoint;
      email.contactPointLastUpdatedDate = DateTime.valueOf(
        currentResponse.LastModifiedDate
      );
      system.debug(
        '**contactPointLastUpdatedDate' + email.contactPointLastUpdatedDate
      );
      CDPDataUIResponse.contactPointEmails.Add(email);
      sortEmailAddresses(CDPDataUIResponse.contactPointEmails);
    } catch (Exception e) {
      // Added on 05 Jan, 2022
      Logger.error('Response parsing error. ' + e.getMessage());
      Logger.saveLog();
      throw new AuraHandledException(e.getMessage());
    }
  }

  //method to get data source record id
  private static Map<String, List<String>> getDataSourceRecordId(
    List<String> UPIds,
    Integer responseSize,
    CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse,
    List<String> dataSourceOrgIds,
    List<String> dataSourceObjectNames,
    Map<String, List<String>> dataSourceRecordIdMap
  ) {
    for (integer upiIndex = 0; upiIndex < UPIds.size(); upiIndex++) {
      List<String> dataSourceRecordIds = new List<String>();
      for (integer i = 0; i < responseSize; i++) {
        CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[
          i
        ];

        if (UPIds[upiIndex] != currentResponse.Id) {
          continue;
        }

        //list to fill dataSourceRecordId
        List<string> sourceRecordData = currentResponse.SourceRecord.split(',');
        String dataSourceRecordId = sourceRecordData[2];
        String dataSourceObjectName = sourceRecordData[1];

        if (!dataSourceRecordIds.Contains(dataSourceRecordId))
          dataSourceRecordIds.Add(dataSourceRecordId);

        //list to fill data source org ids
        string dataSourceOrgId = sourceRecordData[0];
        if (!dataSourceOrgIds.Contains(dataSourceOrgId))
          dataSourceOrgIds.Add(dataSourceOrgId);

        //list to fill data source object name
        if (
          dataSourceRecordIds.Contains(dataSourceRecordId) &&
          !dataSourceObjectNames.Contains(dataSourceObjectName)
        ) {
          dataSourceObjectNames.Add(dataSourceObjectName);
        }
      }

      dataSourceRecordIdMap.Put(UPIds[upiIndex], dataSourceRecordIds);
    }
    return dataSourceRecordIdMap;
  }

  //method to sort email as per last modified date
  private static void sortEmailAddresses(
    list<CDPSearchModels.EmailAddress> emailAddresses
  ) {
    // sort the emails based upon last updated date
    system.debug('sort');
    for (integer i = 0; i < emailAddresses?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < emailAddresses?.size(); j++) {
        system.debug('date' + emailAddresses[j].contactPointLastUpdatedDate);
        system.debug('date1' + emailAddresses[min].contactPointLastUpdatedDate);
        if (
          emailAddresses[j].contactPointLastUpdatedDate >
          emailAddresses[min].contactPointLastUpdatedDate
        ) {
          CDPSearchModels.EmailAddress temp = emailAddresses[min];
          emailAddresses[min] = emailAddresses[j];
          emailAddresses[j] = temp;
        }
      }
    }
  }
  //method to sort phone number as per last modified date
  private static void sortPhoneNumbers(
    list<CDPSearchModels.PhoneNumber> phoneNumbers
  ) {
    // sort the phone numbers based upon last updated date
    for (integer i = 0; i < phoneNumbers?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < phoneNumbers?.size(); j++) {
        if (
          phoneNumbers[j].contactPointLastUpdatedDate >
          phoneNumbers[min].contactPointLastUpdatedDate
        ) {
          CDPSearchModels.PhoneNumber temp = phoneNumbers[min];
          phoneNumbers[min] = phoneNumbers[j];
          phoneNumbers[j] = temp;
        }
      }
    }
  }
  //method to sort address as per last modified date
  private static void sortAddresses(list<CDPSearchModels.Address> addresses) {
    // sort the addresses based upon last updated date
    for (integer i = 0; i < addresses?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < addresses?.size(); j++) {
        if (
          addresses[j].contactPointLastUpdatedDate >
          addresses[min].contactPointLastUpdatedDate
        ) {
          CDPSearchModels.Address temp = addresses[min];
          addresses[min] = addresses[j];
          addresses[j] = temp;
        }
      }
    }
  }
  //method to sort party id (physician registration no) as per last modified date
  private static void sortPartyIdentifications(
    list<CDPSearchModels.PartyIdentification> partyIdentifications
  ) {
    // sort the party identifications based upon last updated date
    system.debug('*** partyIdentifications ' + partyIdentifications);
    for (integer i = 0; i < partyIdentifications?.size() - 1; i++) {
      integer min = i;
      for (integer j = i + 1; j < partyIdentifications?.size(); j++) {
        if (
          partyIdentifications[j].contactPointLastUpdatedDate >
          partyIdentifications[min].contactPointLastUpdatedDate
        ) {
          CDPSearchModels.PartyIdentification temp = partyIdentifications[min];
          partyIdentifications[min] = partyIdentifications[j];
          partyIdentifications[j] = temp;
        }
      }
    }
  }
}
