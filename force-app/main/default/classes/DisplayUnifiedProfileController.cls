/*
  @description       : To display the unified profile view for contact and lead
  @author            : Arjita Marelay
  @group             : 
  @last modified on  : 01-04-2022
  @last modified by  : Arjita Marelay
  Modifications Log 
  Ver   Date         Author        Modification
  1.0   01-04-2022   Arjita Marelay   Initial Version
*/

public class DisplayUnifiedProfileController {
  private static string ERROR_STATUS = 'Error';

  public static void displayUnifiedProfile() {
    HTTPResponse httpResponse = new HTTPResponse();
    //try {
    String cdpSearchIndividualObj = callUnifiedProfileAPI();
    UnifiedProfileViewUIResponse cdpResponseData = getCDPAfterMappingData(
      cdpSearchIndividualObj
    );
    //httpResponse = callGlobalProfileAPI();
    System.debug('#RES: ' + httpResponse.getBody());
    /*}catch(Exception ex) {
            UnifiedProfileViewUIResponse responseObj = new UnifiedProfileViewUIResponse();
            responseObj.status = ERROR_STATUS;
            responseObj.errorMessage = ERROR_STATUS + ' - ' + ex.getMessage();
            Logger.error('There is an error in the Global Profile. ERROR: '+ ex.getMessage());
            Logger.saveLog();
            //return responseObj;
        }*/

    if (httpResponse.getStatusCode() != 200) {
      UnifiedProfileViewUIResponse responseObj = new UnifiedProfileViewUIResponse();
      responseObj.status = ERROR_STATUS;
      responseObj.errorMessage = httpResponse.getBody();
      Logger.error(
        'There is an error in the Global Profile callout. ERROR: ' +
        httpResponse.getBody()
      );
      Logger.saveLog();
      //return responseObj;
    }
    string response = httpResponse.getBody();
    //UnifiedProfileViewUIResponse customer360Data = getCDPAfterMappingData(response);
    Logger.info('Global profile callout done successfully.');
    Logger.saveLog();
    //return customer360Data;
  }

  private static String callUnifiedProfileAPI() {
    String dummyHttpResponse = '{"data": [{"UPID": "0033Z00002NrP5aQAF","personName": "Lascar ioan Gogeneata","firstName": "Lascar ioan","lastName": "Gogeneata","email": "lascar-ioan.gogeneata@chru-strasbourg.fr","secondaryEmail": "","phone": "","mobilePhone": "","street": "10 RUE HANNAH AREE","otherStreet": "","city": "STRASBOURG","state": "67","postalCode": "67200","country": "France","dataSourceObjectId": "Contact","dataSourceId": "Salesforce_00D760000008aLq","physicianRegistrationNo": "10101721354","createdDate": "2019-10-21T09:35:33.000+00:00","lastModifiedDate": "2021-10-18T03:35:28.000+00:00"}],"startTime": "2022-01-04T07:11:29.431149Z","endTime": "2022-01-04T07:11:30.355526Z","rowCount": 2,"queryId": "c8c9f9a3-4b50-4685-9097-b6f1f95be89c", }';
    CDPSearchWrapper.CDPSearchIndividual cdpSearchIndividualObj = (CDPSearchWrapper.CDPSearchIndividual) JSON.deserialize(
      dummyHttpResponse,
      CDPSearchWrapper.CDPSearchIndividual.class
    );
    return dummyHttpResponse;
  }

  public static UnifiedProfileViewUIResponse getCDPAfterMappingData(
    string response
  ) {
    CDPSearchWrapper.CDPSearchIndividual cdpSearchIndividualObj = (CDPSearchWrapper.CDPSearchIndividual) JSON.deserialize(
      response,
      CDPSearchWrapper.CDPSearchIndividual.class
    );
    System.debug('cdpSearchIndividualObj---' + cdpSearchIndividualObj);
    return new UnifiedProfileViewUIResponse();
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

  public class UnifiedProfileViewUIResponse {
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
    public list<contactPointResponse> MobileContactPoints { get; set; }
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
