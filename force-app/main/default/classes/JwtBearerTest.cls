public class JwtBearerTest {
  /*private static final string CONTACTID_PREFIX = '003';
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
        .org_name__c;
    
    @AuraEnabled
    public static CDPSearchModels.UIFinalResponseWrapper getCDPResponse(String searchExpression) {
        CDPSearchModels.UIFinalResponseWrapper finalResponseList = new CDPSearchModels.UIFinalResponseWrapper();
        List<CDPSearchModels.UIFinalResponse> CDPFinalUIResponseList = new List<CDPSearchModels.UIFinalResponse>();                       
        CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse = CDP_APIUtls.getQueryAPIResponse(searchExpression);
        
        //metadata to map data source name
        Map<string,string> dataSourceNameMap = new Map<string,string>();
        dataSourceNameMap = JwtBearerTest.getDataSourceName();
        
        system.debug('***** dataSourceNameMap '+dataSourceNameMap);
        
        Integer responseSize = unifiedProfileResponse.data.size();
        List<String> UPIds = new List<String>();
        
        //List for filling UPIds
        UPIds = JwtBearerTest.getUPID( responseSize,
                                    unifiedProfileResponse,
                                    UPIds);
                
        List<String> dataSourceOrgIds = new List<String>();
        List<String> dataSourceObjectNames = new List<String>();
        
        //initialize UPIds and dataSourceRecord Id map
        Map<String, List<String>> dataSourceRecordIdMap = new Map<String, List<String>>();
        dataSourceRecordIdMap = JwtBearerTest.getDataSourceRecordId( UPIds,
                                                       responseSize,
                                                       unifiedProfileResponse,dataSourceOrgIds,dataSourceObjectNames,
                                                       dataSourceRecordIdMap );
                
        for(String currentUPId : dataSourceRecordIdMap.keySet()){           
            CDPSearchModels.UIFinalResponse CDPDataUIResponse = new CDPSearchModels.UIFinalResponse();
            CDPDataUIResponse.dataSourcePoints = new List<CDPSearchModels.DataSourcePoint>();
            CDPDataUIResponse.contactPointEmails = new List<CDPSearchModels.EmailAddress>();
            CDPDataUIResponse.phoneNumbers = new List<CDPSearchModels.PhoneNumber>();
            CDPDataUIResponse.fullAddress = new List<CDPSearchModels.Address>();
            CDPDataUIResponse.partyIdentifications = new List<CDPSearchModels.PartyIdentification>();
            CDPDataUIResponse.datasourceObjectNames = new List<string>();
            CDPDataUIResponse.dataSources = '';
            CDPDataUIResponse.canCreatecontact = true;//default value to display create new button
            
            List<String> dataSourceRecordIds = dataSourceRecordIdMap.get(currentUPId);
            
            Integer dataSourceRecordIdListSize = dataSourceRecordIds.size();            
            for(Integer i=0;i<dataSourceRecordIdListSize;i++){                                
                String currentDataSourceId = dataSourceRecordIds[i]; 
                // to display source record id
                CDPSearchModels.DataSourcePoint dataSourcePoint = new CDPSearchModels.DataSourcePoint();                                                              
                dataSourcePoint.dataSourcerecordId = currentDataSourceId;
                
                
                // to display data source name                                  			          
                if(dataSourceNameMap.containsKey(dataSourceOrgIds[i])){                    
                    CDPDataUIResponse.dataSources += dataSourceNameMap.get(dataSourceOrgIds[i]) + '~~';                    
                }
                
                // to display data source object record names     
                CDPDataUIResponse.datasourceObjectNames.add(dataSourceObjectNames[i]);
                
                
                for(Integer j=0; j<responseSize; j++){     
                    
                    CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[j];  
                    if(currentResponse.Id != currentUPId)
                        continue;
                    
                    //to map UPID to response
                    CDPDataUIResponse.UPId = currentResponse?.Id;
                    
                    List<string> sourceRecordData =  currentResponse.SourceRecord.split(',');
                    String tempDataSourceId = sourceRecordData[2];
                    string dataSourceName = sourceRecordData[1];
                    string orgid = sourceRecordData[0];                                                                                                                    
                    
                    
                    if(currentDataSourceId != tempDataSourceId)
                        continue;  
                    //sourceRecordData[2] =  '0030100000JUxMyAAL';
                    if(dataSourceNameMap.get(orgid) == SALES_CLOUD_NAME) {
                        dataSourcePoint = checkUsersAccessToRecord(
                            sourceRecordData[2], sourceRecordData[1], dataSourceNameMap.get(orgid), CDPDataUIResponse, false);
                        System.debug('data access--' + CDPDataUIResponse.canCreateContact);
                    }
                    
                    Set<String> sourceorg = new Set<String>();                     
                    //display first name and last name - starts
                    if(currentResponse.ContactPointType == 'INDIVIDUAL'){                        
                        List<string> fullName = JwtBearerTest.parseName(currentResponse);
                        
                        CDPDataUIResponse.firstName = fullName[0];
                        if(fullName.size() > 1){
                            CDPDataUIResponse.lastName = fullName[1];  
                        }
                    } 
                    //display first name and last name - ends
                    
                    // to display email                    
                    if(currentResponse.ContactPointType == 'EMAIL'){
                    parseEmailResponse(currentResponse,
                                                CDPDataUIResponse);
                    }
                    else if(currentResponse.ContactPointType == 'SECONDARY EMAIL'){
                    parseEmailResponse(currentResponse,
                                                CDPDataUIResponse);
                    }
                    // to display  mobile phone
                     else if(currentResponse.ContactPointType == 'MOBILE PHONE' ){
                    parsePhoneResponse(currentResponse,
                                                CDPDataUIResponse,'Mobile',false);
                     }
                    // to display phone
                     else if(currentResponse.ContactPointType == 'PHONE' ){
                       parsePhoneResponse(currentResponse,
                                                CDPDataUIResponse,'Home',true);  
                     }
                    // to display Address
                    else if(currentResponse.ContactPointType == 'ADDRESS' ){
                    parseAddressResponse(currentResponse,
                                                  CDPDataUIResponse);
                    }
                    // to display party id
                    else if(currentResponse.ContactPointType == 'PARTYID' ){
                    parsePartyidResponse(currentResponse,
                                                  CDPDataUIResponse);
                    }
                }
                CDPDataUIResponse.dataSourcePoints.add(dataSourcePoint); 
                
            }                              
            CDPFinalUIResponseList.add(CDPDataUIResponse);
                                     
        }
        //to get the search prefix as per the value entered in input box
        string searchPrefix = getSearchPrefix(searchExpression);
        // append local leads and contacts (Salesforce local database) in the response
            appendLocalProfileDataInResponse(
                CDPFinalUIResponseList,
                searchExpression,
                searchPrefix
            );
        finalResponseList.unifiedProfileData = CDPFinalUIResponseList;        
        return finalResponseList;
    }  
    
    //metadata method to get Data source name
    private static Map<String,String> getDataSourceName() {
        Map<string,string> dataSourceNameMap = new Map<string,string>();                
        CDP_Source_Name__mdt[] SourceRecords = [Select MasterLabel, org_name__c,
                                            SourceID__c from CDP_Source_Name__mdt];
        
        for(CDP_Source_Name__mdt record:SourceRecords) {                                        
            dataSourceNameMap.put(record.SourceID__c,record.org_name__c);             
        }                
        return dataSourceNameMap;
    }
    
    //method to get parse firstName and lastName
    private static List<String> parseName(CDPSearchModels.CDPUnifiedProfile currentResponse) {
        CDPSearchModels.UIFinalResponse CDPDataUIResponse = new CDPSearchModels.UIFinalResponse();
        List<String> fullName =  currentResponse?.ContactPoint.split(',');                                           
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
                WHERE
                UserId = :userInfo.getUserId()
                AND RecordId = :dataSourceRecordId
                LIMIT 1
            ];
        }        
        
        // populate the dataSourcePoint instance based on user's access
        if (userAccess.HasReadAccess) {
            responseObj.canCreatecontact =
                (responseObj.canCreatecontact && false) ||
                hasNonSalesCloudContactData;
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
                (responseObj.canCreatecontact && true) ||
                hasNonSalesCloudContactData;
            dataSourcePoint.isSalesforceRecord = false;            
            dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
        } else if (
            !userAccess.HasReadAccess &&
            dataSourceObjectName.contains(CONTACT_OBJECT_NAME)
        ) {            
            responseObj.canCreateContact =
                (responseObj.canCreatecontact && true) ||
                hasNonSalesCloudContactData;
            dataSourcePoint.isSalesforceRecord = false;            
            dataSourcePoint.dataSourcerecordId = userAccess.RecordId;
        }        
        return dataSourcePoint;
    }
    
    //method to display label for salesforce sales cloud record i.e Contact details or Lead details
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
            isSalesforceRecord == true &&
            dataSourceRecordId.startsWith(LEADID_PREFIX)
        ) {
            recordLabel = 'Lead Details';
        }
        return recordLabel;
    }
    
    //method to get all UPIDs
    public static List<String> getUPID(Integer responseSize,
                                     CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse,
                                     List<String> UPIds){
                                         for (integer i = 0; i < responseSize; i++) {
                                             CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[i];
                                             
                                             if(!UPIds.contains(currentResponse.Id)){
                                                 UPIds.add(currentResponse.Id);  
                                                 
                                             }                                                
                                         } 
                                         return UPIds;                        
                                     }
    //method to parse Party id response - physician registration no
    public static void parsePartyidResponse(CDPSearchModels.CDPUnifiedProfile currentResponse,
                                       CDPSearchModels.UIFinalResponse CDPDataUIResponse){
                                           
                                               CDPSearchModels.PartyIdentification partyIdentification = new CDPSearchModels.PartyIdentification();
                                               List<String> partyIdentifications =  currentResponse?.ContactPoint.split(',');
                                               
                                               partyIdentification.identifierName = partyIdentifications[0];
                                               if(partyIdentifications.size()> 1){
                                                   partyIdentification.identificationNumber = partyIdentifications[1];    
                                               }
                                               system.debug('*** partyIdentifications135 '+partyIdentification);
                                               
                                               CDPDataUIResponse.partyIdentifications.add(partyIdentification);  
                                           sortPartyIdentifications(CDPDataUIResponse.partyIdentifications);
                                       }
    //parse address response
    public static void parseAddressResponse(CDPSearchModels.CDPUnifiedProfile currentResponse,
                                       CDPSearchModels.UIFinalResponse CDPDataUIResponse){
                                           
                                               CDPSearchModels.Address address = new CDPSearchModels.Address();
                                               List<String> fulladdress =  currentResponse?.ContactPoint.split('~');
                                               address.addressLine1 = fulladdress[0];
                                               if(fulladdress.size() > 1){
                                                   address.cityName = fulladdress[1];
                                               }
                                               if(fulladdress.size() > 2){
                                                   address.stateProvinceName = fulladdress[2];
                                               }
                                               if(fulladdress.size() > 3){
                                                   address.postalCode = fulladdress[3];
                                               }
                                               if(fulladdress.size() > 4){
                                                   address.countryName = fulladdress[4];
                                               }
                                               CDPDataUIResponse.fullAddress.add(address);                        
                                           sortAddresses(CDPDataUIResponse.fullAddress);
                                       }
    //parse mobile phone and phone
    public static void parsePhoneResponse(CDPSearchModels.CDPUnifiedProfile currentResponse,
                                     CDPSearchModels.UIFinalResponse CDPDataUIResponse,String contactType,Boolean isContactType){
                                        
                                             CDPSearchModels.PhoneNumber phoneNumber = new CDPSearchModels.PhoneNumber();
                                             phoneNumber.telephoneNumber = currentResponse.ContactPoint;
                                         phoneNumber.contactPointLastUpdatedDate = DateTime.valueOf(currentResponse.LastModifiedDate);
                                             phoneNumber.isContactType = isContactType;   
                                             phoneNumber.contactType = contactType;   
                                             CDPDataUIResponse.phoneNumbers.add(phoneNumber);  
                                         	sortPhoneNumbers(CDPDataUIResponse.phoneNumbers);
                                         
                                     }
	//parse email and secondary email                                        
	public static void parseEmailResponse(CDPSearchModels.CDPUnifiedProfile currentResponse,
                                     CDPSearchModels.UIFinalResponse CDPDataUIResponse){
                                         system.debug('test!!');                                         
                                             CDPSearchModels.EmailAddress email = new CDPSearchModels.EmailAddress();
                                             email.emailAddressName = currentResponse.ContactPoint;
                                             email.contactPointLastUpdatedDate = DateTime.valueOf(currentResponse.LastModifiedDate);                                                                                                                                                                                                                                             
                                         	 system.debug('**contactPointLastUpdatedDate'+email.contactPointLastUpdatedDate);
                                             CDPDataUIResponse.contactPointEmails.Add(email);                                          
                                         	 sortEmailAddresses(CDPDataUIResponse.contactPointEmails); 
                                     }
    
	//method to get data source record id  
    private static Map<String, List<String>> getDataSourceRecordId(List<String> UPIds,
                                                      Integer responseSize,
                                                      CDPSearchModels.CDPUnifiedProfileResponse unifiedProfileResponse,List<String> dataSourceOrgIds ,
                                                      List<String> dataSourceObjectNames,
                                                      Map<String, List<String>> dataSourceRecordIdMap ) {
                                                          
                                                          for(integer upiIndex = 0; upiIndex < UPIds.size(); upiIndex++)
                                                          {
                                                              List<String> dataSourceRecordIds = new List<String>();                        
                                                              for (integer i = 0; i < responseSize; i++) {
                                                                  CDPSearchModels.CDPUnifiedProfile currentResponse = unifiedProfileResponse.data[i];  
                                                                  
                                                                  if(UPIds[upiIndex] != currentResponse.Id){
                                                                      continue;
                                                                  }
                                                                  
                                                                  //list to fill dataSourceRecordId
                                                                  List<string> sourceRecordData =  currentResponse.SourceRecord.split(',');
                                                                  String dataSourceRecordId = sourceRecordData[2];
                                                                  String dataSourceObjectName =  sourceRecordData[1];
                                                                  
                                                                  if(!dataSourceRecordIds.Contains(dataSourceRecordId))
                                                                      dataSourceRecordIds.Add(dataSourceRecordId);
                                                                  
                                                                  //list to fill data source org ids
                                                                  string dataSourceOrgId = sourceRecordData[0];
                                                                  if(!dataSourceOrgIds.Contains(dataSourceOrgId))
                                                                      dataSourceOrgIds.Add(dataSourceOrgId);
                                                                  
                                                                  //list to fill data source object name
                                                                  if(dataSourceRecordIds.Contains(dataSourceRecordId) && !dataSourceObjectNames.Contains(dataSourceObjectName)){
                                                                      dataSourceObjectNames.Add(dataSourceObjectName);
                                                                  }
                                                                                                                                    
                                                              }
                                                              
                                                              dataSourceRecordIdMap.Put(UPIds[upiIndex], dataSourceRecordIds);                        
                                                          }
                                                          return dataSourceRecordIdMap;
                                                      }
    //method to append local salesforce data in response
    private static void appendLocalProfileDataInResponse(
        List<CDPSearchModels.UIFinalResponse> response,
        string searchExpression,
        string searchPrefix
    ) {
        // check leads and contacts locally        
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
        } else if (searchPrefix == SFSC_LOCAL_ID_SEARCH_PREFIX) {
            if (searchExpression.startsWith(CONTACTID_PREFIX)) {
                contacts = getLocalContactRecordForId(searchExpression);
            } else if (searchExpression.startsWith(LEADID_PREFIX)) {
                leads = getLocalLeadRecordForId(searchExpression);
            }
        }

        appendLocalContactsToResponse(response, contacts);
        appendLocalLeadsToResponse(response, leads);
    }
    
    //method for appending local contact
    public static void appendLocalContactsToResponse(
        List<CDPSearchModels.UIFinalResponse> CDPResponseList,
        List<Contact> dbContacts
    ) {
        
        // iterate over local contacts and set the 'isLocalRecord' if a contact is not present in the C360 API response
        for (Contact contact : dbContacts) {
            Boolean isLocalRecord = true;
            if (isLocalRecord) {
                for (
                    CDPSearchModels.UIFinalResponse CDPResponse : CDPResponseList
                ) {
                    if (isLocalRecord) {
                        for (
                            Integer i = 0;
                            i < CDPResponse?.dataSourcePoints?.size();
                            i++
                        ) {
                            if (
                                String.valueOf(contact.Id) ==
                                CDPResponse.dataSourcePoints[i]
                                    .dataSourceRecordId
                            ) {
                                isLocalRecord = false;
                                break;
                            }
                        }
                    }
                }
            }

            // add the contact in response if it's local (not present in C360 API response)
            if (isLocalRecord) {
                // create a new instance and populate fields
                CDPSearchModels.UIFinalResponse localContact = new CDPSearchModels.UIFinalResponse();

                // basic fields
                localContact.firstName = contact.FirstName;
                localContact.lastName = contact.LastName;
                localContact.dataSources = SALESCLOUD_NAME;

                // data sources
                localContact.dataSourcePoints = new List<CDPSearchModels.DataSourcePoint>();
                CDPSearchModels.DataSourcePoint dataSourcePoint = new CDPSearchModels.DataSourcePoint();
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
                localContact.phoneNumbers = new List<CDPSearchModels.PhoneNumber>();
                // mobile phones
                CDPSearchModels.PhoneNumber mobilePhone = new CDPSearchModels.PhoneNumber();
                if (contact.MobilePhone != null) {
                    mobilePhone.telephoneNumber = contact.MobilePhone;
                    mobilePhone.isContactType = false;
                    localContact.phoneNumbers.add(mobilePhone);
                }

                // phones
                CDPSearchModels.PhoneNumber phone = new CDPSearchModels.PhoneNumber();
                if (contact.Phone != null) {
                    phone.telephoneNumber = contact.Phone;
                    phone.extensionNumber = contact.Extension__c;
                    phone.isContactType = true;
                    localContact.phoneNumbers.add(phone);
                }

                // emails
                localContact.contactPointEmails = new List<CDPSearchModels.EmailAddress>();
                // primary emails
                CDPSearchModels.EmailAddress primaryEmail = new CDPSearchModels.EmailAddress();
                if (contact.Email != null) {
                    primaryEmail.emailAddressName = contact.Email;
                    localContact.contactPointEmails.add(primaryEmail);
                }

                // secondary emails
                CDPSearchModels.EmailAddress secondaryEmail = new CDPSearchModels.EmailAddress();
                if (contact.Secondary_Email__c != null) {
                    secondaryEmail.emailAddressName = contact.Secondary_Email__c;
                    localContact.contactPointEmails.add(secondaryEmail);
                }

                // mailing address
                localContact.fullAddress = new List<CDPSearchModels.Address>();

                CDPSearchModels.Address mailingAddress = new CDPSearchModels.Address();
                mailingAddress.addressLine1 = contact.MailingStreet;
                mailingAddress.addressLine2 = contact.OtherStreet;
                mailingAddress.cityName = contact.MailingCity;
                mailingAddress.postalCode = contact.MailingPostalCode;
                mailingAddress.stateProvinceName = contact.MailingState;
                mailingAddress.stateProvinceCode = contact.MailingStateCode;
                mailingAddress.countryName = contact.MailingCountry;
                localContact.fullAddress.add(mailingAddress);

                // set 'isGlobalRecord' flag indicating the record is not synced yet
                localContact.isCDPRecord = false;

                // add the local contact to the final reponse list
                CDPResponseList.add(localContact);
            }
        }
    }
    //method for appending local leads
    public static void appendLocalLeadsToResponse(
        List<CDPSearchModels.UIFinalResponse> CDPResponseList,
        List<Lead> dbLeads
    ) {
        // iterate over local leads and set the 'isLocalRecord' if a lead is not present in the C360 API response

        for (Lead lead : dbLeads) {
            Boolean isLocalRecord = true;
            if (isLocalRecord) {
                for (
                    CDPSearchModels.UIFinalResponse globalResponse : CDPResponseList
                ) {
                    if (isLocalRecord) {
                        for (
                            Integer i = 0;
                            i < globalResponse?.dataSourcePoints?.size();
                            i++
                        ) {
                            if (
                                string.valueOf(lead.Id) ==
                                globalResponse.dataSourcePoints[i]
                                    .dataSourceRecordId
                            ) {
                                isLocalRecord = false;
                                break;
                            }
                        }
                    }
                }
            }

            // add the lead in response if it's local (not present in C360 API response)
            if (isLocalRecord) {
                CDPSearchModels.UIFinalResponse localLead = new CDPSearchModels.UIFinalResponse();

                // basic fields
                localLead.firstName = lead.FirstName;
                localLead.lastName = lead.LastName;
                localLead.dataSources = SALESCLOUD_NAME;

                // data sources
                localLead.dataSourcePoints = new List<CDPSearchModels.DataSourcePoint>();
                CDPSearchModels.DataSourcePoint dataSourcePoint = new CDPSearchModels.DataSourcePoint();
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
                localLead.phoneNumbers = new List<CDPSearchModels.PhoneNumber>();
                // mobile phones
                CDPSearchModels.PhoneNumber mobilePhone = new CDPSearchModels.PhoneNumber();
                if (lead.MobilePhone != null) {
                    mobilePhone.telephoneNumber = lead.MobilePhone;
                    mobilePhone.isContactType = false;
                    localLead.phoneNumbers.add(mobilePhone);
                }

                // phones
                CDPSearchModels.PhoneNumber phone = new CDPSearchModels.PhoneNumber();
                if (lead.Phone != null) {
                    phone.telephoneNumber = lead.Phone;
                    phone.extensionNumber = lead.Extension__c;
                    phone.isContactType = true;
                    localLead.phoneNumbers.add(phone);
                }

                // emails
                localLead.contactPointEmails = new List<CDPSearchModels.EmailAddress>();
                // primary emails
                CDPSearchModels.EmailAddress primaryEmail = new CDPSearchModels.EmailAddress();
                if (lead.Email != null) {
                    primaryEmail.emailAddressName = lead.Email;
                    localLead.contactPointEmails.add(primaryEmail);
                }

                // mailing address
                localLead.fullAddress = new List<CDPSearchModels.Address>();

                CDPSearchModels.Address mailingAddress = new CDPSearchModels.Address();
                mailingAddress.addressLine1 = lead.Street;
                mailingAddress.cityName = lead.City;

                mailingAddress.postalCode = Lead.PostalCode;
                mailingAddress.stateProvinceName = lead.State;
                mailingAddress.stateProvinceCode = lead.StateCode;
                mailingAddress.countryName = lead.Country;
                localLead.fullAddress.add(mailingAddress);

                // set 'isGlobalRecord' flag indicating the record is not synced yet
                localLead.isCDPRecord = false;

                // add the local lead to the final reponse list
                CDPResponseList.add(localLead);
            }
        }
    }
    
    //get local records for email and phone
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

    //get local records for SFSC contact Id
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

    //get local records for SFSC lead Id
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
    //get search prefix as per input value
    private static string getSearchPrefix(String searchExpression) {
        String searchPrefix = '';

        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}[\\.\\w]*$';

        String globalPartyIdRegex = '.*?-gpid-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';

        Boolean emailMatchFlag = Pattern.matches(emailRegex, searchExpression);
        // Boolean phoneMatchFlag = Pattern.matches(phoneRegex, searchExpression);
        Boolean globalPartyIdFlag = Pattern.matches(
            globalPartyIdRegex,
            searchExpression
        );
        Boolean localIdFlag =
            searchExpression.startsWithIgnoreCase(CONTACTID_PREFIX) ||
            searchExpression.startsWithIgnoreCase(LEADID_PREFIX);

        if (emailMatchFlag) {
            searchPrefix = EMAIL_SEARCH_PREFIX;
            //system.debug('** inside email' + searchPrefix);
        } 
        else if (localIdFlag) {
            // either a contact or lead ID
            // get relevant global party ID from the Salesforce database
            system.debug('** inside SFSC id ');
            searchPrefix = SFSC_LOCAL_ID_SEARCH_PREFIX;
        } else {
            // phone number
            system.debug('** inside else' + searchPrefix);
            searchPrefix = PHONE_SEARCH_PREFIX;
        }

        return searchPrefix;
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
                system.debug('date'+emailAddresses[j].contactPointLastUpdatedDate );
                system.debug('date1'+  emailAddresses[min].contactPointLastUpdatedDate);
                if (
                    emailAddresses[j].contactPointLastUpdatedDate >
                    emailAddresses[min].contactPointLastUpdatedDate 
                ) {
                    CDPSearchModels.EmailAddress temp = emailAddresses[
                        min
                    ];
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
                    CDPSearchModels.PhoneNumber temp = phoneNumbers[
                        min
                    ];
                    phoneNumbers[min] = phoneNumbers[j];
                    phoneNumbers[j] = temp;
                }
            }
        }
    }
    //method to sort address as per last modified date
    private static void sortAddresses(
        list<CDPSearchModels.Address> addresses
    ) {
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
        for (integer i = 0; i < partyIdentifications?.size() - 1; i++) {
            integer min = i;
            for (integer j = i + 1; j < partyIdentifications?.size(); j++) {
                if (
                    partyIdentifications[j].contactPointLastUpdatedDate >
                    partyIdentifications[min].contactPointLastUpdatedDate
                ) {
                    CDPSearchModels.PartyIdentification temp = partyIdentifications[
                        min
                    ];
                    partyIdentifications[min] = partyIdentifications[j];
                    partyIdentifications[j] = temp;
                }
            }
        }
    }*/
  public static void getMetadataResponse() {
    HttpRequest req = new HttpRequest();
    req.setMethod('GET');
    req.setHeader('Connection', 'keep-alive');
    req.setHeader('Content-Type', 'application/json');
    //req.setEndpoint('callout:CDPQuery/api/v1/metadata/');
    //req.setEndpoint('callout:CDP_Authentication/api/v1/metadata/');
    req.setEndpoint('callout:CDPQuery');
    req.setHeader('Accept', '*/*');
    req.setHeader(
      '{!$Credential.AuthorizationMethod}',
      '{!$Credential.AuthorizationHeaderValue}'
    );
    //req.setBody('UserName:{!HTMLENCODE($Credential.Username)}');
    //req.setBody('Password:{!HTMLENCODE($Credential.Password)}');
    //system.debug('*** request '+ req.getBody());
    Http http = new Http();
    HTTPResponse res = http.send(req);
    system.debug('*** response ' + res.getBody());
  }
}
