@isTest
public with sharing class GlobalSearchBeforeCreateControllerTest {
    @testSetup static void setup() {
        //Create common test accounts
        List<Account> testAccounts = new List<Account>();
        Account account = new Account();
        account.Name = 'Infosys';
        testAccounts.add(account);
        
        insert testAccounts;
        
        // Create common test contacts
        List<Contact> testContacts = new List<Contact>();
        Contact contact = new Contact();  
        contact.FirstName = 'Oliver';
        contact.LastName = 'Miller';
        contact.Email = 'oliver1@gmail.com';
        contact.Secondary_Email__c = 'oliver1@gmail.com';
        contact.Phone = '+493355684338';
        contact.MobilePhone = '+49876543211';        
        contact.MailingCity = 'Dearborn';
        contact.MailingStreet = 'Tully Poot.';
        contact.MailingState = 'Florida';
        contact.MailingPostalCode = '124567';
        contact.MailingCountry = ' United States Of America ';
        contact.Job_Function__c = 'Accounting';
        contact.GlobalPartyId = 'CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8';
        contact.AccountId = testAccounts[0].Id;
        contact.Contact_Origin__c = 'Contact Tab';
        testContacts.add(contact);        
        
        insert testContacts; 
        system.debug('** testContacts '+testContacts[0].id);
        
        //Create common test accounts
        List<Lead> testLeads = new List<Lead>();
        Lead lead = new Lead();  
        lead.FirstName = 'Menard';
        lead.LastName = 'Drewe';
        lead.Email = 'mdrewe57@geocities.jp';
        lead.Phone = '+493355684338';
        lead.MobilePhone = '+89567895432';
        lead.City = 'Dearborn';
        lead.Street = 'Tully Poot.';
        lead.State = 'Florida';
        lead.PostalCode = '124567';
        lead.Country = ' United States Of America ';
        lead.Job_Function__c = 'Accounting';   
        lead.Company = 'Infosys';
        lead.GlobalPartyId= 'CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8';
        testLeads.add(lead);
        
        insert testLeads;  
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
                
        User usr = new User();
        usr.FirstName='Global Profile';
        usr.LastName = 'Test';
        usr.Alias = 'GloT';
        // usr.Email = 'test.global@gmail.com';
        usr.Email = 'kjagdale@wlgore.com';
        usr.Username = 'kjagdale@wlgore.com';
        usr.ProfileId = profileId.id;
        usr.TimeZoneSidKey = 'GMT';
        usr.LanguageLocaleKey = 'en_US';
        usr.EmailEncodingKey = 'UTF-8';
        usr.LocaleSidKey = 'en_US';  
        usr.Country = 'United States Of America';
        usr.Division = 'FAB';
        usr.EmployeeNumber ='1256';
        usr.External_Id__c = 'TestExt1234';
        system.debug('** user '+usr);
            
        /*User usr1 = new User();
        usr1.FirstName='Global Profile1';
        usr1.Alias = 'GloT1';
        usr1.Email = 'test.global@gmail.com1';
        usr1.Username = 'test.global@gmail.com1';
        usr1.ProfileId = profileId.id;
        usr1.TimeZoneSidKey = 'GMT';
        usr1.LanguageLocaleKey = 'en_US';
        usr1.EmailEncodingKey = 'UTF-8';
        usr1.LocaleSidKey = 'en_US';*/        

        //assign manager id 
        usr.ManagerId =  UserInfo.getUserId() ;
        //usr1.ManagerId = UserInfo.getUserId() ;
        
		        
        List<User> usrList = new List<User>();
        usrList.add(usr);    
        //usrList.add(usr1);                
        insert usrList;
    	}
        public static testmethod void  getGlobalProfileForEmail() {
            Test.startTest();
            // Setting up the mock response
            Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());
                   
            //create a user and profile
           	List<User> user = [SELECT Id, FirstName,LastName,Email FROM User where Email='kjagdale@wlgore.com'];                       
            system.debug('** user id test'+user[0].id);    
            system.debug('** user id test'+user[0].Email);                                      
            
            Customer360SearchModels.Global360DataWrapper customer360Data;    
            List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();        
            //System.runAs(user[0]){
                customer360Data = GlobalSearchBeforeCreateController.searchGlobalData('oliver@gmail.com');
            //}  
            system.debug('*** customer360Data '+customer360Data);
            allData = customer360Data.globalProfileData; 
            //get contacts
        	List<Contact> contacts = [Select id,GlobalPartyId,FirstName,LastName,Email,Secondary_Email__c,Phone,MobilePhone,Extension__c,MailingStreet,MailingState, MailingCountry,MailingPostalCode,MailingStateCode,MailingCity,OtherStreet from Contact];
        
        	//get leads
        	List<Lead> leads = [select Id,GlobalPartyId,FirstName,LastName,Email,Extension__c,Phone,MobilePhone,Street,State, Country,PostalCode,City,StateCode from Lead];
        
            GlobalSearchBeforeCreateController.appendLocalContactsToResponse(allData,contacts);
            GlobalSearchBeforeCreateController.appendLocalLeadsToResponse(allData,leads);
            Test.stopTest();
        }
    public static testmethod void  getGlobalProfileForPhone(){
        Test.startTest();
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());
                        
        Customer360SearchModels.Global360DataWrapper customer360Data;        
        List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();        
        customer360Data = GlobalSearchBeforeCreateController.searchGlobalData('+499876543498');  
        allData = customer360Data.globalProfileData; 
        //get contacts
        List<Contact> contacts = [Select id,GlobalPartyId,FirstName,LastName,Email,Secondary_Email__c,Phone,MobilePhone,Extension__c,MailingStreet,MailingState, MailingCountry,MailingPostalCode,MailingStateCode,MailingCity,OtherStreet from Contact];
        
        //get leads
        List<Lead> leads = [select Id,GlobalPartyId,FirstName,LastName,Email,Extension__c,Phone,MobilePhone,Street,State, Country,PostalCode,City,StateCode from Lead];
        
        GlobalSearchBeforeCreateController.appendLocalContactsToResponse(allData,contacts);
        GlobalSearchBeforeCreateController.appendLocalLeadsToResponse(allData,leads);
        Test.stopTest();        
    }
    public static testmethod void  getGlobalProfileForGlobalParty(){
        Test.startTest();
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());
                        
        Customer360SearchModels.Global360DataWrapper customer360Data;        
        List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();        
        customer360Data = GlobalSearchBeforeCreateController.searchGlobalData('CRE-creiad000007kn4-gpid-a1243d87-f425-4249-8315-efe1455529d8');                                                               
        allData = customer360Data.globalProfileData; 
        //get contacts
        List<Contact> contacts = [Select id,GlobalPartyId,FirstName,LastName,Email,Secondary_Email__c,Phone,MobilePhone,Extension__c,MailingStreet,MailingState, MailingCountry,MailingPostalCode,MailingStateCode,MailingCity,OtherStreet from Contact];
        
        //get leads
        List<Lead> leads = [select Id,GlobalPartyId,FirstName,LastName,Email,Extension__c,Phone,MobilePhone,Street,State, Country,PostalCode,City,StateCode from Lead];
                                    
        GlobalSearchBeforeCreateController.appendLocalContactsToResponse(allData,contacts);
        GlobalSearchBeforeCreateController.appendLocalLeadsToResponse(allData,leads);  
        GlobalSearchBeforeCreateController.getGlobalPartyId(contacts[0].id); 
        GlobalSearchBeforeCreateController.getGlobalPartyId(leads[0].id);           
        Test.stopTest();        
    }
    public static testmethod void  getGlobalProfileForLocalSFSCIdLead(){
        Test.startTest();
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());
                        
        Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
        List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();        
        
        //get leads
        List<Lead> leads = [select Id,GlobalPartyId,FirstName,LastName,Email,Extension__c,Phone,MobilePhone,Street,State, Country,PostalCode,City,StateCode from Lead];
        
        customer360Data = GlobalProfileData.getGlobalProfile(leads[0].id);        
        allData = customer360Data.allData;        
                             
        GlobalProfileData.appendLocalLeadsToResponse(allData,leads);
                        
        Test.stopTest();        
    }
    public static testmethod void  getGlobalProfileForLocalSFSCIdContact(){
        Test.startTest();
        // Setting up the mock response
        Test.setMock(HTTPCalloutMock.class, new GlobalProfileDataMock());
                        
        Customer360SearchModels.Global360DataWrapper customer360Data = new Customer360SearchModels.Global360DataWrapper();
        List<Customer360SearchModels.GlobalProfileFinalResponse> allData = new List<Customer360SearchModels.GlobalProfileFinalResponse>();        
        
        //get contacts
        List<Contact> contacts = [Select id,GlobalPartyId,FirstName,LastName,Email,Secondary_Email__c,Phone,MobilePhone,Extension__c,MailingStreet,MailingState, MailingCountry,MailingPostalCode,MailingStateCode,MailingCity,OtherStreet from Contact];               
        
        customer360Data = GlobalProfileData.getGlobalProfile(contacts[0].id); 
        system.debug('*** customer360Data Id '+customer360Data);
        allData = customer360Data.allData;        
                
        GlobalProfileData.appendLocalContactsToResponse(allData,contacts);     
        
        string dataSourceIdContact = '0032g00000NwG0sAAF';
        string dataSourceIdLead= '00Q2g00000NwG0sAAF';
        GlobalProfileData.setContactLeadDetailsLabel(dataSourceIdContact,true);
        GlobalProfileData.setContactLeadDetailsLabel(dataSourceIdLead,true);   
                        
        Test.stopTest();        
    }
}