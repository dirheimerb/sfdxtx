/**
 * @description       : 
 * @author            : BDirheimer
 * @group             : 
 * @last modified on  : 02-08-2022
 * @last modified by  : BDirheimer
**/
public with sharing class CDPRestViewController {
    @AuraEnabled
    public static List<Contact> getContactFields(){
        return [
            SELECT
                Id,
                Email, 
                Phone,
                MobilePhone,
]
    
}
