/**
* @description       : 
* @author            : BDirheimer
* @group             : 
* @last modified on  : 3rd Feb 2022
* @last modified by  : Kalyani

Modifications Log 
Ver   Date         Author       Modification
1.0   3rd Feb 2022 Kalyani   Initial Version  
**/
@isTest
public class CDP_APIUtilsTest {
    private static final String FAKE_TOKEN = 'fakeToken';

    @testSetup
    static void setup() {
        
    }
    private class Mock implements HttpCalloutMock {        
        public HTTPResponse respond(HTTPRequest req) {
            
            HTTPResponse res = new HTTPResponse();
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getBody().contains('grant_type'), req.getBody());
            System.assert(req.getBody().contains('assertion'), req.getBody());
            
            res.setStatusCode(200);
            res.setBody('{"instance_url":"https://gorecdp-dev.my.salesforce.com","scope" :"cdpquery api cdpprofile full","token_type":"Bearer","id":"https://login.salesforce.com/id/00D5e000001PjlyEAC/0055e000007KC7AAAW","access_token":"' + FAKE_TOKEN + '"}');            
            return res;
        }
    }
    public static testMethod void getSearchStringTest() {
        String searchStringForEmail = CDP_APIUtls.getSearchString('test1@gmail.com','email');   
        String searchStringForPhone = CDP_APIUtls.getSearchString('714343222345','phone');   
        String searchStringForMobilePhone = CDP_APIUtls.getSearchString('714343222345','mobilePhone'); 
        String searchStringForSecEmail = CDP_APIUtls.getSearchString('sec@test.com','secemail'); 
    }
    
     public static testMethod void getToken() {
        //Refrences: 
        //https://salesforce.stackexchange.com/questions/174406/how-do-you-use-a-mock-response-when-calling-auth-jwtbearertokenexchange-getacces
        //https://ideas.salesforce.com/s/idea/a0B8W00000GdcXHUAZ/ability-to-unit-test-authjwtbearertokenexchangegetaccesstoken
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDP_APIUtilsMock());        
        Map<String,String> getBearerToken = CDP_APIUtls.getJWTBearerToken();           
        CDP_APIUtls.getQueryAPIResponse('test1@gmail.com','email');
        CDP_APIUtls.getUnifiedProfileViewResponse('003WDLLLLLL');
        
        Test.stopTest();
        
    }

}