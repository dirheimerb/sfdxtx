/*
@description       : 
@author            : Kalyani Jagdale
@group             : 
@last modified on  : 09-16-2021
@last modified by  : BDirheimer
Modifications Log 
Ver   Date         Author        Modification
1.0   06-01-2021   Kalyani Jagdale   Initial Version
*/

public class CDP_DisplayUnifiedProfile {
  public static string testdata = '';
  private static final string CONTACTID_PREFIX = '003';
  private static final string LEADID_PREFIX = '00Q';
  private static String SALES_CLOUD_NAME = 'Sales Cloud';
  private static final string LEAD_OBJECT_NAME = 'Lead';
  private static final string CONTACT_OBJECT_NAME = 'Contact';
  private static final string PHONE_SEARCH_PREFIX = 'phoneNumber';
  private static final string EMAIL_SEARCH_PREFIX = 'emailaddress';
  private static final string SFSC_LOCAL_ID_SEARCH_PREFIX = 'sfscLocalId';
  private static string SALESCLOUD_NAME = CDP_Source_Name__mdt.getInstance(
      'Sales_Cloud'
    )
    .CDP_DataSource_Name__c;
  private static string CONTACT_TYPE_NAME_EMAIL = 'Email';
  private static string CONTACT_TYPE_NAME_PHONE = 'Phone';
  private static string CONTACT_TYPE_NAME_MOBILE = 'Mobile';
  private static string CONTACT_TYPE_NAME_HOME = 'Home';
  private static string CONTACT_TYPE_NAME_ADDRESS = 'Address';
  private static string SEARCH_PREFIX = 'globalPartyId';
  private static string ERROR_STATUS = 'Error';
  private static string SUCCESS_STATUS = 'Success';
  private static string CONTACT_SOBJECT = 'Contact';
  private static string LEAD_SOBJECT = 'Lead';
  private static final string EMAIL = 'EMAIL';
  private static final string SECONDARYEMAIL = 'SECONDARY EMAIL';
  private static final string MOBILEPHONE = 'MOBILE PHONE';
  private static final string PHONE = 'PHONE';
  private static final string ADDRESS = 'ADDRESS';
  private static final string PARTYID = 'PARTYID';

  @AuraEnabled(cacheable=true)
  public static UnifiedProfileFinalResponse displayUnifiedProfile(
    String recordId
  ) {
    try {
      UnifiedProfileFinalResponse unifiedProfileUIResponseObj = new UnifiedProfileFinalResponse();
      List<CDPSearchModels.UIFinalResponse> CDPFinalUIResponseList = new List<CDPSearchModels.UIFinalResponse>();
      CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse = new CDPSearchModels.CDPUnifiedProfileResponse();
      //metadata to map data source name
      if (Test.isRunningTest()) {
        unifiedProfileResponse = (CDPSearchModels.CDPUnifiedProfileResponse) JSON.deserialize(
          testdata,
          CDPSearchModels.CDPUnifiedProfileResponse.class
        );
      } else {
        unifiedProfileResponse = CDP_APIUtls.getUnifiedProfileViewResponse(
          recordId
        );
      }
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
        unifiedProfileUIResponseObj.EmailContactPoints = new List<ContactPointResponse>();
        unifiedProfileUIResponseObj.SecondaryEmailContactPoints = new List<ContactPointResponse>();
        unifiedProfileUIResponseObj.PhoneContactPoints = new List<ContactPointResponse>();
        unifiedProfileUIResponseObj.MobileContactPoints = new List<ContactPointResponse>(); //SFSC-4976
        unifiedProfileUIResponseObj.AddressContactPoints = new List<AddressPointResponse>();
        unifiedProfileUIResponseObj.PartyIdentificationContactPoints = new List<ContactPointResponse>();

        List<String> dataSourceRecordIds = dataSourceRecordIdMap.get(
          currentUPId
        );

        Integer dataSourceRecordIdListSize = dataSourceRecordIds.size();
        for (Integer i = 0; i < dataSourceRecordIdListSize; i++) {
          String currentDataSourceId = dataSourceRecordIds[i];
          // to map source record id
          unifiedProfileUIResponseObj.dataSourcerecordId =
            currentDataSourceId + ',';

          // to display data source name

          // to display data source object record names
          //CDPDataUIResponse.datasourceObjectNames.add(dataSourceObjectNames[i]);

          for (Integer j = 0; j < responseSize; j++) {
            CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[
              j
            ];
            if (currentResponse.Id != currentUPId)
              continue;

            //to map UPID to response
            unifiedProfileUIResponseObj.UPId = currentResponse?.Id;

            List<string> sourceRecordData = currentResponse.SourceRecord.split(
              ','
            );
            String tempDataSourceId = sourceRecordData[2];
            string dataSourceName = sourceRecordData[1];
            string orgid = sourceRecordData[0];

            if (currentDataSourceId != tempDataSourceId)
              continue;
            //sourceRecordData[2] =  '0030100000JUxMyAAL';

            Set<String> sourceorg = new Set<String>();
            //display first name and last name - starts
            if (currentResponse.ContactPointType == 'INDIVIDUAL') {
              List<string> fullName = parseName(currentResponse);

              unifiedProfileUIResponseObj.firstName = fullName[0];
              if (fullName.size() > 1) {
                unifiedProfileUIResponseObj.lastName = fullName[1];
              }
            }
            //display first name and last name - ends

            // to display email
            if (currentResponse.ContactPointType == EMAIL) {
              parseEmailResponse(
                currentResponse,
                unifiedProfileUIResponseObj,
                'Email',
                dataSourceNameMap,
                dataSourceOrgIds[i]
              );
            } else if (currentResponse.ContactPointType == SECONDARYEMAIL) {
              parseEmailResponse(
                currentResponse,
                unifiedProfileUIResponseObj,
                'SecondaryEmail',
                dataSourceNameMap,
                dataSourceOrgIds[i]
              );
            } else if (currentResponse.ContactPointType == MOBILEPHONE) {
              // to display  mobile phone
              parsePhoneResponse(
                currentResponse,
                unifiedProfileUIResponseObj,
                'Mobile',
                false,
                dataSourceNameMap,
                dataSourceOrgIds[i]
              );
            } else if (currentResponse.ContactPointType == PHONE) {
              // to display phone
              parsePhoneResponse(
                currentResponse,
                unifiedProfileUIResponseObj,
                'Home',
                true,
                dataSourceNameMap,
                dataSourceOrgIds[i]
              );
            } else if (currentResponse.ContactPointType == ADDRESS) {
              // to display Address
              parseAddressResponse(
                currentResponse,
                unifiedProfileUIResponseObj,
                dataSourceNameMap,
                dataSourceOrgIds[i]
              );
            }
          }
        }
        // CDPFinalUIResponseList.add(CDPDataUIResponse);
      }
      //finalResponseList.unifiedProfileData = CDPFinalUIResponseList;

      return unifiedProfileUIResponseObj;
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

  //parse address response
  public static void parseAddressResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    UnifiedProfileFinalResponse responseObj,
    Map<String, String> dataSourceNameMap,
    String dataSourceOrgIds
  ) {
    AddressPointResponse contactPointAddress = new AddressPointResponse();
    if (
      currentResponse.ContactPoint != null &&
      currentResponse.ContactPoint != ''
    ) {
      List<String> fulladdress = currentResponse?.ContactPoint.split('~');

      contactPointAddress.addressLine1 = (fulladdress[0] != null)
        ? fulladdress[0]
        : '';
      if (fulladdress.size() > 1) {
        contactPointAddress.cityName = (fulladdress[1] != null)
          ? fulladdress[1]
          : '';
      }
      if (fulladdress.size() > 2) {
        contactPointAddress.stateProvinceName = (fulladdress[2] != null)
          ? fulladdress[2]
          : '';
      }
      if (fulladdress.size() > 3) {
        contactPointAddress.postalCode = (fulladdress[3] != null)
          ? fulladdress[3]
          : '';
      }
      if (fulladdress.size() > 4) {
        contactPointAddress.countryName = (fulladdress[4] != null)
          ? fulladdress[4]
          : '';
      }

      if (dataSourceNameMap.containsKey(dataSourceOrgIds)) {
        contactPointAddress.dataSourceName = dataSourceNameMap.get(
          dataSourceOrgIds
        );
      }
      responseObj.AddressContactPoints.add(contactPointAddress);
    }
  }
  //parse mobile phone and phone
  public static void parsePhoneResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    UnifiedProfileFinalResponse responseObj,
    String contactType,
    Boolean isContactType,
    Map<String, String> dataSourceNameMap,
    String dataSourceOrgIds
  ) {
    ContactPointResponse contactPointPhone = new ContactPointResponse();
    if (contactType == 'Home') {
      if (
        currentResponse.ContactPoint != null &&
        currentResponse.ContactPoint != ''
      ) {
        contactPointPhone.contactPointValue = currentResponse.ContactPoint;
        contactPointPhone.contactPointType = currentResponse.ContactPointType;
        if (dataSourceNameMap.containsKey(dataSourceOrgIds)) {
          contactPointPhone.dataSourceName = dataSourceNameMap.get(
            dataSourceOrgIds
          );
        }
        responseObj.PhoneContactPoints.add(contactPointPhone);
      }
    } else if (contactType == 'Mobile') {
      if (
        currentResponse.ContactPoint != null &&
        currentResponse.ContactPoint != ''
      ) {
        contactPointPhone.contactPointValue = currentResponse.ContactPoint;
        contactPointPhone.contactPointType = currentResponse.ContactPointType;

        if (dataSourceNameMap.containsKey(dataSourceOrgIds)) {
          contactPointPhone.dataSourceName = dataSourceNameMap.get(
            dataSourceOrgIds
          );
        }
        responseObj.MobileContactPoints.add(contactPointPhone);
      }
    }
  }
  //parse email and secondary email
  public static void parseEmailResponse(
    CDPSearchModels.CDPUnifiedProfile currentResponse,
    UnifiedProfileFinalResponse responseObj,
    String emailType,
    Map<String, String> dataSourceNameMap,
    String dataSourceOrgIds
  ) {
    ContactPointResponse contactPointEmail = new ContactPointResponse();
    if (emailType == 'Email') {
      if (
        currentResponse.ContactPoint != null &&
        currentResponse.ContactPoint != ''
      ) {
        contactPointEmail.contactPointValue = currentResponse.ContactPoint;
        contactPointEmail.contactPointType = currentResponse.ContactPointType;

        if (dataSourceNameMap.containsKey(dataSourceOrgIds)) {
          contactPointEmail.dataSourceName = dataSourceNameMap.get(
            dataSourceOrgIds
          );
        }
        responseObj.EmailContactPoints.Add(contactPointEmail);
      }
    } else if (emailType == 'SecondaryEmail') {
      if (
        currentResponse.ContactPoint != null &&
        currentResponse.ContactPoint != ''
      ) {
        contactPointEmail.contactPointValue = currentResponse.ContactPoint;
        contactPointEmail.contactPointType = currentResponse.ContactPointType;

        if (dataSourceNameMap.containsKey(dataSourceOrgIds)) {
          contactPointEmail.dataSourceName = dataSourceNameMap.get(
            dataSourceOrgIds
          );
        }
        responseObj.SecondaryEmailContactPoints.Add(contactPointEmail);
      }
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

  @AuraEnabled
  public static string adoptContactDetails(string adoptDetailsJSON) {
    String response = '';
    System.debug('adoptDetailsJSON----' + adoptDetailsJSON);
    AdoptContactDetailWrapper adoptDetailsWrapper = (AdoptContactDetailWrapper) JSON.deserialize(
      adoptDetailsJSON,
      AdoptContactDetailWrapper.class
    );
    System.debug('adoptDetailsWrapper----' + adoptDetailsWrapper);
    if (adoptDetailsWrapper.sObjectName == CONTACT_SOBJECT) {
      Contact contactRec = new Contact(Id = adoptDetailsWrapper.recordID);
      if (
        adoptDetailsWrapper.adoptedEmailValues != null &&
        adoptDetailsWrapper.adoptedEmailValues.contactPointValue != null
      ) {
        contactRec.Email = adoptDetailsWrapper.adoptedEmailValues.contactPointValue;

        // SFSC-5244 Blank out Verification field on addoption Oct 21,21
        contactRec.Email_Verification_Status__c = null;
        contactRec.Email_Verification_Date__c = null;
      }

      if (
        adoptDetailsWrapper.adoptedSecondaryEmailValues != null &&
        adoptDetailsWrapper.adoptedSecondaryEmailValues.contactPointValue !=
        null
      ) {
        system.debug(
          '**** secondary email ' +
          adoptDetailsWrapper.adoptedSecondaryEmailValues.contactPointValue
        );
        contactRec.Secondary_Email__c = adoptDetailsWrapper.adoptedSecondaryEmailValues.contactPointValue;
        contactRec.Secondary_Email_Verification_Status__c = null;
        contactRec.Secondary_Email_Verification_Date__c = null;

        system.debug('**** EmailS ' + contactRec.Secondary_Email__c);
      }

      if (
        adoptDetailsWrapper.adoptedPhoneValues != null &&
        adoptDetailsWrapper.adoptedPhoneValues.contactPointValue != null
      ) {
        //SFSC-4976
        contactRec.Phone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;

        //-5244 Blank out Verification field on addoption Oct 21,21
        contactRec.Phone_Verification_Status__c = null;
        contactRec.Phone_Verification_Date__c = null;
      }
      if (
        adoptDetailsWrapper.adoptedMobileValues != null &&
        adoptDetailsWrapper.adoptedMobileValues.contactPointValue != null
      ) {
        contactRec.MobilePhone = adoptDetailsWrapper.adoptedMobileValues.contactPointValue; //SFSC-4976

        //SFSC-5244 Blank out Verification field on addoption Oct 21,21
        contactRec.Mobile_Phone_Verification_Status__c = null;
        contactRec.Mobile_Phone_Verification_Date__c = null;
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

        //SFSC -5244 Blank out Verification field on addoption Oct 21,21
        contactRec.Address_Verification_Status__c = null;
        contactRec.Address_Verification_Date__c = null;
      }

      try {
        // Added on 12 Jan 2022 for skip Duplicate Rule ---SFSC - 5598-----
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.update(contactRec, dml);
        if (sr.isSuccess()) {
          response = SUCCESS_STATUS;
        } else {
          String errorString = '';
          for (Database.Error error : sr.getErrors()) {
            errorString += error.getMessage();
          }
          response = 'Error - ' + errorString.unescapeHtml4();
        }

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
        //SFSC-4976
        leadRec.Phone = adoptDetailsWrapper.adoptedPhoneValues.contactPointValue;
      }
      if (
        adoptDetailsWrapper.adoptedMobileValues != null &&
        adoptDetailsWrapper.adoptedMobileValues.contactPointValue != null
      ) {
        leadRec.MobilePhone = adoptDetailsWrapper.adoptedMobileValues.contactPointValue;
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
        // Added on 12 Jan 2022 for skip Duplicate Rule ---SFSC - 5598-----
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
    public ContactPointResponse adoptedEmailValues;
    @AuraEnabled
    public ContactPointResponse adoptedSecondaryEmailValues;
    @AuraEnabled
    public ContactPointResponse adoptedPhoneValues;
    @AuraEnabled
    public ContactPointResponse adoptedMobileValues; //SFSC-4976
    @AuraEnabled
    public AddressPointResponse adoptedAddressValues;
    @AuraEnabled
    public ContactPointResponse adoptedPartyIdentificationValues;
  }

  public class ContactPointResponse {
    @AuraEnabled
    public string contactPointValue;
    @AuraEnabled
    public string contactPointType;
    @AuraEnabled
    public string dataSourceName;
  }

  public class AddressPointResponse {
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

  public class UnifiedProfileFinalResponse {
    @AuraEnabled
    public string firstName { get; set; }
    @AuraEnabled
    public string lastName { get; set; }
    @AuraEnabled
    public string UPId { get; set; }
    @AuraEnabled
    public string dataSourceRecordId { get; set; }
    @AuraEnabled
    public list<ContactPointResponse> EmailContactPoints { get; set; }
    @AuraEnabled
    public list<ContactPointResponse> SecondaryEmailContactPoints { get; set; }
    @AuraEnabled
    public list<ContactPointResponse> PhoneContactPoints { get; set; }
    @AuraEnabled
    public list<ContactPointResponse> MobileContactPoints { get; set; } //SFSC-4976
    @AuraEnabled
    public list<AddressPointResponse> AddressContactPoints { get; set; }
    @AuraEnabled
    public list<ContactPointResponse> PartyIdentificationContactPoints {
      get;
      set;
    }
    @AuraEnabled
    public string errorMessage { get; set; }
    @AuraEnabled
    public string status { get; set; }
  }
}
