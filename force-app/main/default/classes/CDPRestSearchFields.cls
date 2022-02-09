/**
 * @description       : 
 * @author            : BDirheimer
 * @group             : 
 * @last modified on  : 02-08-2022
 * @last modified by  : BDirheimer
**/
public with sharing class CDPRestSearchFields {
    @AuraEnabled(cacheable=true)
    public static Object validateObject(CDPRestTable responseObject) {
        Object obj = responseObject.searchObject;
        return obj; 
    }
}
