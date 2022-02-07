/**
* @description       : 
* @author            : BDirheimer
* @group             : 
* @last modified on  : 12-01-2021
* @last modified by  : BDirheimer

Modifications Log 
Ver   Date         Author       Modification
1.0   01-05-2021   BDirheimer   Initial Version  
1.1   01-05-2021   Kalyani   	  Modified query for Unified profile view  
**/

public with sharing class CDP_APIUtls 
{
    public static String QUERY_API = '/api/v1/query';   
    //public static String QUERY_API = '/services/data/v53.0/ssot/query';
    private static final string CONTACTID_PREFIX = '003';
    private static final string LEADID_PREFIX = '00Q'; 
    private static string SALESCLOUD_DATASOURCE_ID = CDP_Source_Name__mdt.getInstance(
        'Sales_Cloud'
    )
        .CDP_SourceID__c;
    public static String getSearchString(String searchInput,String searchType) {
        try{            
            if(searchType == 'email') {
                System.debug('emailMatch');
                return '(SELECT UnifiedContactPointEmail__dlm.ssot__PartyId__c '+
            	' AS UnifiedRecordId__c FROM ContactPointEmailIdentityLink__dlm LEFT JOIN UnifiedContactPointEmail__dlm ON '+
            	' ContactPointEmailIdentityLink__dlm.UnifiedRecordId__c = UnifiedContactPointEmail__dlm.ssot__Id__c where UnifiedContactPointEmail__dlm.ssot__EmailAddress__c = \''+searchInput+'\' UNION ALL '+
                 'SELECT unifiedindividual__dlm.ssot__Id__c AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm '+
                 'ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c '+ 
                 'where unifiedindividual__dlm.Secondary_Email_c__c =  \''+searchInput+'\')';
            }                                                            
             else if(searchType == 'phone'){
                system.debug('**** inside phone flag');                 
                return '(SELECT UnifiedContactPointPhone__dlm.ssot__PartyId__c '+
            	' AS UnifiedRecordId__c FROM ContactPointPhoneIdentityLink__dlm LEFT JOIN UnifiedContactPointPhone__dlm ON '+
            	' ContactPointPhoneIdentityLink__dlm.UnifiedRecordId__c = UnifiedContactPointPhone__dlm.ssot__Id__c where UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c = \''+searchInput+'\')';
            }
            else if(searchType == 'mobilePhone'){
                system.debug('**** inside mobile phone flag');                 
                return '(SELECT unifiedindividual__dlm.ssot__Id__c AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm '+
                 'ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c '+ 
                 'where unifiedindividual__dlm.mobilephone__c =  \''+searchInput+'\')';
            }
            else {
                System.debug('local id');                
                return '(SELECT UnifiedIndividual__dlm.ssot__Id__c '+
            	' AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm ON '+
            	' IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c where UnifiedIndividual__dlm.ssot__ExternalRecordId__c = \''+searchInput+'\')';
            }
        } catch (Exception e) {
            // Added on 05 Jan, 2022
            Logger.error('There is something wrong with the string search term. ERROR: '+ e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());    
        }
    } 
    /*public static String getSearchString(String searchInput,String searchType) {
        try{
            //String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}[\\.\\w]*$';
            //Boolean emailMatchFlag = Pattern.matches(emailRegex, searchInput);
            //String unifiedPartyIdRegex = '[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}';
           // Boolean unifiedPartyIdMatchFlag = Pattern.matches(unifiedPartyIdRegex, searchInput);           
            if(emailMatchFlag) {
                System.debug('emailMatch');
                return '(SELECT UnifiedContactPointEmail__dlm.ssot__PartyId__c '+
            	' AS UnifiedRecordId__c FROM ContactPointEmailIdentityLink__dlm LEFT JOIN UnifiedContactPointEmail__dlm ON '+
            	' ContactPointEmailIdentityLink__dlm.UnifiedRecordId__c = UnifiedContactPointEmail__dlm.ssot__Id__c where UnifiedContactPointEmail__dlm.ssot__EmailAddress__c = \''+searchInput+'\' UNION ALL '+
                 'SELECT unifiedindividual__dlm.ssot__Id__c AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm '+
                 'ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c '+ 
                 'where unifiedindividual__dlm.Secondary_Email_c__c =  \''+searchInput+'\')';
            }
                                                
            //70924e05-c98a-3843-bd16-8f0beccfe232
             else if(localIdFlag){
                system.debug('**** inside local id flag');
                return '(SELECT UnifiedIndividual__dlm.ssot__Id__c '+
            	' AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm ON '+
            	' IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c where UnifiedIndividual__dlm.ssot__ExternalRecordId__c = \''+searchInput+'\')';
            }
            else {
                System.debug('phonematch');
                //return 'UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c = \''+searchInput+'\'';
                return '(SELECT UnifiedContactPointPhone__dlm.ssot__PartyId__c '+
            	' AS UnifiedRecordId__c FROM ContactPointPhoneIdentityLink__dlm LEFT JOIN UnifiedContactPointPhone__dlm ON '+
            	' ContactPointPhoneIdentityLink__dlm.UnifiedRecordId__c = UnifiedContactPointPhone__dlm.ssot__Id__c where UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c = \''+searchInput+'\' UNION ALL '+
                 'SELECT unifiedindividual__dlm.ssot__Id__c AS UnifiedRecordId__c FROM IndividualIdentityLink__dlm LEFT JOIN UnifiedIndividual__dlm '+
                 'ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c '+ 
                 'where unifiedindividual__dlm.mobilephone__c =  \''+searchInput+'\')';
            }
        } catch (Exception e) {
            // Added on 05 Jan, 2022
            Logger.error('There is something wrong with the string search term. ERROR: '+ e.getMessage());
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());    
        }
    } */
    
    public static CDPSearchModels.CDPUnifiedProfileResponse getQueryAPIResponse(String searchInput,String searchType)
    {      
        
        //String searchInput='zzmohd@eastman.com';
        String searchInputMatch = getSearchString(searchInput,searchType);
        System.debug('searchInputMatch--'+searchInputMatch);
        Map<String, Object> pAuthenticationMap = new Map<String, Object>();
        Map<String, Object> metadataResMap = new Map<String, Object>();
        
         String queryParams = 'SELECT OccuranceCnt, Id, ContactPoint, ContactPointType, SourceRecord, CreatedDate, LastModifiedDate FROM ( SELECT COUNT(*) as OccuranceCnt, UnifiedIndividual__dlm.ssot__Id__c AS Id, '+
            '\'INDIVIDUAL\' as ContactPointType, UnifiedIndividual__dlm.ssot__FirstName__c || \',\' || UnifiedIndividual__dlm.ssot__LastName__c AS ContactPoint, '+
            'IndividualIdentityLink__dlm.ssot__DataSourceId__c || \',\' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || IndividualIdentityLink__dlm.SourceRecordId__c AS '+
            'SourceRecord,  cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR) AS CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) AS LastModifiedDate '+
            'FROM UnifiedIndividual__dlm LEFT JOIN IndividualIdentityLink__dlm ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c GROUP BY '+
            'UnifiedIndividual__dlm.ssot__Id__c, UnifiedIndividual__dlm.ssot__FirstName__c || \',\' || UnifiedIndividual__dlm.ssot__LastName__c, IndividualIdentityLink__dlm.ssot__DataSourceId__c '+
            '|| \',\' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || IndividualIdentityLink__dlm.SourceRecordId__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR), '+
            'cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointAddress__dlm.ssot__PartyId__c AS Id, '+
            '\'ADDRESS\' as ContactPointType, UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CityId__c || \'~\' || '+
            'UnifiedContactPointAddress__dlm.ssot__StateProvinceName__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CountryName__c AS '+
            'ContactPoint, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            'ContactPointAddressIdentityLink__dlm.SourceRecordId__c AS SourceRecord,cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c As VARCHAR) AS CreatedDate, '+
            'cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) AS LastModifiedDate FROM UnifiedContactPointAddress__dlm LEFT JOIN ContactPointAddressIdentityLink__dlm ON '+
            'UnifiedContactPointAddress__dlm.ssot__Id__c = ContactPointAddressIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointAddress__dlm.ssot__PartyId__c, '+
            'UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CityId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__StateProvinceName__c '+
            '|| \'~\' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CountryName__c, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c '+
            '|| \',\' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointAddressIdentityLink__dlm.SourceRecordId__c, '+
            'cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c as VARCHAR), cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) '+
            'UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointEmail__dlm.ssot__PartyId__c AS Id, \'EMAIL\' AS ContactPointType, UnifiedContactPointEmail__dlm.ssot__EmailAddress__c AS '+
            'ContactPoint, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            'ContactPointEmailIdentityLink__dlm.SourceRecordId__c AS SourceRecord, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, '+
            'cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM UnifiedContactPointEmail__dlm LEFT JOIN ContactPointEmailIdentityLink__dlm ON '+
            'UnifiedContactPointEmail__dlm.ssot__Id__c = ContactPointEmailIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointEmail__dlm.ssot__PartyId__c, '+
            'UnifiedContactPointEmail__dlm.ssot__EmailAddress__c, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c '+
            '|| \',\' || ContactPointEmailIdentityLink__dlm.SourceRecordId__c, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) , '+
            'cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,\'SECONDARY EMAIL\' '+
            'AS ContactPointType,unifiedindividual__dlm.Secondary_Email_c__c AS ContactPoint,individualidentitylink__dlm.ssot__datasourceid__c || \',\'|| '+
            'individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\'|| individualidentitylink__dlm.sourcerecordid__c AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR)'+
            ' As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON '+
            ' unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.Secondary_Email_c__c,'+
            ' individualidentitylink__dlm.ssot__datasourceid__c || \',\' || individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\' || individualidentitylink__dlm.sourcerecordid__c,'+
            ' cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR), cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, '+
            ' UnifiedPartyIdentification__dlm.ssot__PartyId__c AS Id, \'PARTYID\' AS ContactPointType, UnifiedPartyIdentification__dlm.ssot__PartyIdentificationTypeId__c || \',\' || '+
            ' UnifiedPartyIdentification__dlm.ssot__IdentificationNumber__c AS ContactPoint, PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || \',\' || '+
            ' PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || PartyIdentificationIdentityLink__dlm.SourceRecordId__c AS SourceRecord,'+
            ' cast(UnifiedPartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate,cast(UnifiedPartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM UnifiedPartyIdentification__dlm LEFT JOIN PartyIdentificationIdentityLink__dlm ON UnifiedPartyIdentification__dlm.ssot__Id__c = PartyIdentificationIdentityLink__dlm.UnifiedRecordId__c'+
            ' GROUP BY UnifiedPartyIdentification__dlm.ssot__PartyId__c, UnifiedPartyIdentification__dlm.ssot__PartyIdentificationTypeId__c || \',\' || UnifiedPartyIdentification__dlm.ssot__IdentificationNumber__c, '+
            ' PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || \',\' || PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            ' PartyIdentificationIdentityLink__dlm.SourceRecordId__c, cast(UnifiedPartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR),'+
            ' cast(UnifiedPartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointPhone__dlm.ssot__PartyId__c AS Id, '+
            ' \'PHONE\' AS ContactPointType, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c AS ContactPoint, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c || \',\' || '+
            ' ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c AS SourceRecord,'+
            ' cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM UnifiedContactPointPhone__dlm LEFT JOIN ContactPointPhoneIdentityLink__dlm ON UnifiedContactPointPhone__dlm.ssot__Id__c = ContactPointPhoneIdentityLink__dlm.UnifiedRecordId__c '+
            ' GROUP BY UnifiedContactPointPhone__dlm.ssot__PartyId__c, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c '+
            ' || \',\' || ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c, '+
            ' cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR),cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) '+
            ' UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,\'MOBILE PHONE\' AS ContactPointType,unifiedindividual__dlm.MobilePhone__c AS ContactPoint,'+
            ' individualidentitylink__dlm.ssot__datasourceid__c || \',\'|| individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\'|| individualidentitylink__dlm.sourcerecordid__c '+
            ' AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c '+
            ' GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.MobilePhone__c,individualidentitylink__dlm.ssot__datasourceid__c || \',\' || '+
            ' individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\' || individualidentitylink__dlm.sourcerecordid__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR),'+
            ' cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR)) WHERE ContactPoint NOT IN ( \'\', \',,,,\', \',\' ) AND Id IN '+ searchInputMatch +''+
            ' ORDER BY Id, ContactPointType';           
        
        queryParams = queryParams.replace('+', '||');
        
        System.debug('**** QueryParams: '+queryParams);        
        
        HttpRequest req = new HttpRequest();
        
        req.setMethod('POST');
        //req.setHeader('Connection', 'keep-alive');
        //req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        
        if (pAuthenticationMap == null || pAuthenticationMap.size() == 0)
            pAuthenticationMap = CDP_APIUtls.getCDPToken(CDP_APIUtls.getJWTBearerToken());
        
        req.setHeader('Authorization', 'Bearer ' + pAuthenticationMap.get('access_token'));
        
        String body = '{"sql":"' + queryParams + '"}';
        req.setBody(body);        
        req.setEndpoint('https://' + pAuthenticationMap.get('instance_url') + QUERY_API );       
        //req.setEndpoint('callout:CDPQuery/services/data/v53.0/ssot/query');   
        system.debug('*** body'+ req.getBody());
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('*** body'+ req.getBody());
        CDPSearchModels.CDPUnifiedProfileResponse queryRes = new CDPSearchModels.CDPUnifiedProfileResponse();        
        try{
            System.debug('querryRes JSON--'+res.getBody());
            queryRes = (CDPSearchModels.CDPUnifiedProfileResponse)JSON.deserialize(res.getBody(), CDPSearchModels.CDPUnifiedProfileResponse.class);
            System.debug('querryRes11--'+queryRes); 
            
            // Added on 05 Jan, 2022
            Logger.info('Query API response received successfully. RESULT: ' + queryRes);
            Logger.saveLog();
             
        }catch(Exception e){
            system.debug('exception '+ e.getMessage());
            
            // Added on 05 Jan, 2022
            Logger.error('Query API response in error. ERROR: '+ e.getMessage());
            Logger.saveLog();
        }        
        return queryRes;
        
    }  
        
    public static CDPSearchModels.CDPUnifiedProfileResponse getUnifiedProfileViewResponse(String recordId){
        //recordId = '0033Z00002ILN4DQAX'; //hardcoded for testing
        //recordId = '003j0000017mZLDAA2'; //for secondary email 
        recordId = '003j000001J8J5tAAF'; //for mobile phone 
        //String searchInputString= getSearchPrefix(searchInput);        
        Map<String, Object> pAuthenticationMap = new Map<String, Object>();
        Map<String, Object> metadataResMap = new Map<String, Object>();
        String queryParams = '';          
        
        queryParams = 'SELECT OccuranceCnt, Id, ContactPoint, ContactPointType, SourceRecord, CreatedDate, LastModifiedDate FROM ( SELECT COUNT(*) as OccuranceCnt, UnifiedIndividual__dlm.ssot__Id__c AS Id, '+
            '\'INDIVIDUAL\' as ContactPointType, UnifiedIndividual__dlm.ssot__FirstName__c || \',\' || UnifiedIndividual__dlm.ssot__LastName__c AS ContactPoint, '+
            'IndividualIdentityLink__dlm.ssot__DataSourceId__c || \',\' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || IndividualIdentityLink__dlm.SourceRecordId__c AS '+
            'SourceRecord,  cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR) AS CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) AS LastModifiedDate '+
            'FROM UnifiedIndividual__dlm LEFT JOIN IndividualIdentityLink__dlm ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c GROUP BY '+
            'UnifiedIndividual__dlm.ssot__Id__c, UnifiedIndividual__dlm.ssot__FirstName__c || \',\' || UnifiedIndividual__dlm.ssot__LastName__c, IndividualIdentityLink__dlm.ssot__DataSourceId__c '+
            '|| \',\' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || IndividualIdentityLink__dlm.SourceRecordId__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR), '+
            'cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointAddress__dlm.ssot__PartyId__c AS Id, '+
            '\'ADDRESS\' as ContactPointType, UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CityId__c || \'~\' || '+
            'UnifiedContactPointAddress__dlm.ssot__StateProvinceName__c  || \'~\' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CountryName__c AS '+
            'ContactPoint, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            'ContactPointAddressIdentityLink__dlm.SourceRecordId__c AS SourceRecord,cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c As VARCHAR) AS CreatedDate, '+
            'cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) AS LastModifiedDate FROM UnifiedContactPointAddress__dlm LEFT JOIN ContactPointAddressIdentityLink__dlm ON '+
            'UnifiedContactPointAddress__dlm.ssot__Id__c = ContactPointAddressIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointAddress__dlm.ssot__PartyId__c, '+
            'UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CityId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__StateProvinceName__c '+
            '|| \'~\' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || \'~\' || UnifiedContactPointAddress__dlm.ssot__CountryName__c, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c '+
            '|| \',\' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointAddressIdentityLink__dlm.SourceRecordId__c, '+
            'cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c as VARCHAR), cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) '+
            'UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointEmail__dlm.ssot__PartyId__c AS Id, \'EMAIL\' AS ContactPointType, UnifiedContactPointEmail__dlm.ssot__EmailAddress__c AS '+
            'ContactPoint, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            'ContactPointEmailIdentityLink__dlm.SourceRecordId__c AS SourceRecord, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, '+
            'cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM UnifiedContactPointEmail__dlm LEFT JOIN ContactPointEmailIdentityLink__dlm ON '+
            'UnifiedContactPointEmail__dlm.ssot__Id__c = ContactPointEmailIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointEmail__dlm.ssot__PartyId__c, '+
            'UnifiedContactPointEmail__dlm.ssot__EmailAddress__c, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || \',\' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c '+
            '|| \',\' || ContactPointEmailIdentityLink__dlm.SourceRecordId__c, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) , '+
            'cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,\'SECONDARY EMAIL\' '+
            'AS ContactPointType,unifiedindividual__dlm.Secondary_Email_c__c AS ContactPoint,individualidentitylink__dlm.ssot__datasourceid__c || \',\'|| '+
            'individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\'|| individualidentitylink__dlm.sourcerecordid__c AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR)'+
            ' As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON '+
            ' unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.Secondary_Email_c__c,'+
            ' individualidentitylink__dlm.ssot__datasourceid__c || \',\' || individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\' || individualidentitylink__dlm.sourcerecordid__c,'+
            ' cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR), cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, '+
            ' UnifiedPartyIdentification__dlm.ssot__PartyId__c AS Id, \'PARTYID\' AS ContactPointType, UnifiedPartyIdentification__dlm.ssot__Name__c || \',\' || '+
            ' UnifiedPartyIdentification__dlm.ssot__IdentificationNumber__c AS ContactPoint, PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || \',\' || '+
            ' PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || PartyIdentificationIdentityLink__dlm.SourceRecordId__c AS SourceRecord,'+
            ' cast(UnifiedPartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate,cast(UnifiedPartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM UnifiedPartyIdentification__dlm LEFT JOIN PartyIdentificationIdentityLink__dlm ON UnifiedPartyIdentification__dlm.ssot__Id__c = PartyIdentificationIdentityLink__dlm.UnifiedRecordId__c'+
            ' GROUP BY UnifiedPartyIdentification__dlm.ssot__PartyId__c, UnifiedPartyIdentification__dlm.ssot__Name__c || \',\' || UnifiedPartyIdentification__dlm.ssot__IdentificationNumber__c, '+
            ' PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || \',\' || PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || '+
            ' PartyIdentificationIdentityLink__dlm.SourceRecordId__c, cast(UnifiedPartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR),'+
            ' cast(UnifiedPartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointPhone__dlm.ssot__PartyId__c AS Id, '+
            ' \'PHONE\' AS ContactPointType, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c AS ContactPoint, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c || \',\' || '+
            ' ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c AS SourceRecord,'+
            ' cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM UnifiedContactPointPhone__dlm LEFT JOIN ContactPointPhoneIdentityLink__dlm ON UnifiedContactPointPhone__dlm.ssot__Id__c = ContactPointPhoneIdentityLink__dlm.UnifiedRecordId__c '+
            ' GROUP BY UnifiedContactPointPhone__dlm.ssot__PartyId__c, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c '+
            ' || \',\' || ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || \',\' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c, '+
            ' cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR),cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) '+
            ' UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,\'MOBILE PHONE\' AS ContactPointType,unifiedindividual__dlm.MobilePhone__c AS ContactPoint,'+
            ' individualidentitylink__dlm.ssot__datasourceid__c || \',\'|| individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\'|| individualidentitylink__dlm.sourcerecordid__c '+
            ' AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate '+
            ' FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c '+
            ' GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.MobilePhone__c,individualidentitylink__dlm.ssot__datasourceid__c || \',\' || '+
            ' individualidentitylink__dlm.ssot__datasourceobjectid__c || \',\' || individualidentitylink__dlm.sourcerecordid__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR),'+
            ' cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR)) WHERE Id IN (SELECT UnifiedRecordId__c FROM IndividualIdentityLink__dlm ' +
            ' WHERE ssot__DataSourceId__c = \'' + SALESCLOUD_DATASOURCE_ID + '\' AND SourceRecordId__c= \''+ recordId +'\') ORDER BY Id, ContactPointType';  
        
        queryParams = queryParams.replace('+', '||');
        
        System.debug('**** QueryParams: '+queryParams);        
        
        HttpRequest req = new HttpRequest();
        
        req.setMethod('POST');
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        
        /*if (pAuthenticationMap == null || pAuthenticationMap.size() == 0)
            pAuthenticationMap = CDP_APIUtls.getCDPToken(CDP_APIUtls.getJWTBearerToken());
        
        req.setHeader('Authorization', 'Bearer ' + pAuthenticationMap.get('access_token'));*/
        
        String body = '{"sql":"' + queryParams + '"}';
        req.setBody(body);        
        //req.setEndpoint('https://' + pAuthenticationMap.get('instance_url') + QUERY_API );  
        req.setEndpoint('callout:CDPQuery/services/data/v53.0/ssot/query');         
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('*** ');
       CDPSearchModels.CDPUnifiedProfileResponse queryRes = new CDPSearchModels.CDPUnifiedProfileResponse();        
        try{
            System.debug('querryRes JSON--final'+res.getBody());
            queryRes = (CDPSearchModels.CDPUnifiedProfileResponse)JSON.deserialize(res.getBody(), CDPSearchModels.CDPUnifiedProfileResponse.class);
            System.debug('*** querryRes11View final--'+queryRes); 
            // Added on 05 Jan, 2022
            Logger.info('Query API response received successfully. RESULT: ' + queryRes);
            Logger.saveLog();
        }catch(Exception e){
            system.debug('exception '+ e.getMessage());            
            // Added on 05 Jan, 2022
            Logger.error('Query API response in error.: '+ e.getMessage());
            Logger.saveLog();
        }        
        return queryRes;
    }
    public static Map<String, String> getJWTBearerToken()
    {
        Map<String, String> authSettings = getAuthSettings();
        system.debug('authsettings '+ authSettings);
        Auth.JWT jwt = new Auth.JWT();
        
        // These need to be metadata because they would be different for each instance.
        jwt.setSub(authSettings.get('Username')); 
        // This is the client id from the connected app that has a digital signiture
        jwt.setIss(authSettings.get('Client_Id'));
        jwt.setAud(authSettings.get('CDP_Home_Endpoint')); 
        
        Map<String, Object> claims = new Map<String, Object>();
        
        // Scopes must be included in the connected app referenced by the client id used above.        
        claims.put('scope', authSettings.get('Scopes'));
        jwt.setAdditionalClaims(claims);
        
        // Needs to be metadata as the cert name could change
        Auth.JWS jws = new Auth.JWS(jwt, authSettings.get('CertName'));
        
        String token = jws.getCompactSerialization();
        String tokenEndpoint = authSettings.get('CDP_Home_Endpoint') + '/services/oauth2/token';
        
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);	                 
        
        Map<String, String> responseMap = new Map<String,String>(); 
                                
        String accessToken; 
        String respBody;
        if(!Test.isRunningTest()){
            accessToken = bearer.getAccessToken(); 
            respBody = bearer.getHTTPResponse().getBody();
            responseMap = JSONToMap(respBody);
        }else{            
            string fake_access_token = 'fakeToken';
            responseMap.put('instance_url','https://gorecdp-dev.my.salesforce.com');
            responseMap.put('scope','cdpquery api cdpprofile full');
            responseMap.put('token_type','Bearer');
            responseMap.put('id','https://login.salesforce.com/id/00D5e000001PjlyEAC/0055e000007KC7AAAW');
            responseMap.put('access_token',fake_access_token);            
        }
        
        System.debug(LoggingLevel.DEBUG, responseMap);
		system.debug('** responseMap token '+ responseMap);
        
        return responseMap;
    }
    
    
    public static Map<String, String> getCDPToken(Map<String,String> pBearerMap)
    {
        String body = 'grant_type=' + EncodingUtil.urlEncode('urn:salesforce:grant-type:external:cdp', 'UTF-8') + '&' +
            'subject_token=' + pBearerMap.get('access_token') + '&' +
            'subject_token_type=' + EncodingUtil.urlEncode('urn:ietf:params:oauth:token-type:access_token', 'UTF-8');
        System.debug(body);
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        
        req.setMethod('POST');
        //req.setHeader('Connection', 'keep-alive');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setEndpoint(pBearerMap.get('instance_url') + '/services/a360/token');
        req.setBody(body);
        
        // Send the request, and return a response
        HttpResponse response = http.send(req);
        system.debug('**** CDP token request '+ req.getBody());
        
        // If the response is not a good one throw an exception to get out
        if (!response.getStatus().equals('OK')){
            // Added on 05 Jan, 2022
            Logger.error('CDP Token Callout Exception: '+ response.getBody());
            Logger.saveLog();
            throw new CalloutException(response.getBody());
        }
        
        system.debug('**** CDP token response '+ response.getBody());
        Map<String, String> responseMap = JSONToMap(response.getBody());
        System.debug(LoggingLevel.DEBUG, responseMap);
        
        return responseMap;
    }
    
    // Get setting to support authentication from a customer metadata settings object.
    public static Map<String, String> getAuthSettings() {
        Map<String, String> settings = new Map<String, String>();
        
        for (CDP_API_Setting__mdt setting: [
            SELECT 
            DeveloperName, 
            Label, 
            MasterLabel,
            CDP_Setting__c
            FROM CDP_API_Setting__mdt LIMIT 100]) {
                settings.put(setting.DeveloperName, setting.CDP_Setting__c);
                system.debug('****setting '+ setting);
            }
        system.debug('****settings map'+ settings);
        return settings;
    }
    
    public static Map<String, String> JSONToMap(String pJSON) 
    {
        Map<String, String> hashMap = new Map<String, String>();
        
        JSONParser parser = JSON.createParser(pJSON);
        
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() ==  JSONToken.FIELD_NAME) {
                String key = parser.getText(); 
                parser.nextToken();
                hashMap.put(key, parser.getText());
            }
        }//API Name	CDP_API__mdt
        
        System.debug(LoggingLevel.DEBUG, hashMap);
        return hashMap;
    }
        
    public class QueryResponseWrapper {
        public List<QueryDataResponseWrapper> data{get;set;}
        public String startTime{get;set;}
        public String endTime{get;set;}
        public String rowCount{get;set;}
        public String queryId{get;set;}
        public Boolean done{get;set;}
    }
    
    public class QueryDataResponseWrapper{
        public Integer OccuranceCnt {get;set;}
        public String Id {get;set;}
        public String ContactPoint {get;set;}
        public String ContactPointType {get;set;}
        public String SourceRecord {get;set;}
    }
    
}