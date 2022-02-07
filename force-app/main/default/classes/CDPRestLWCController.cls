/**
 * @description       : 
 * @author            : BDirheimer
 * @group             : 
 * @last modified on  : 02-06-2022
 * @last modified by  : BDirheimer
**/

public with sharing class CDPRestLWCController {
    @AuraEnabled
    public static List<Contact> getRecordId(Id contactId, String newValue) {
        return [
            SELECT 
                Id 
            FROM Contact 
            WHERE Id = :contactId 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Contact> getEmailAddress(Id contactId, String newValue) {
        return [
            SELECT
                Id,
                Email
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Contact> getSecondEmailAddress(Id contactId, String newValue) {
        return [
            SELECT
                Id,
                Secondary_Email__c
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Contact> getPhone(Id contactId, String newValue) {
        return [
            SELECT
                Id,
                Phone
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Contact> getMobilePhone(Id contactId, String newValue) {
        return [
            SELECT
                Id,
                MobilePhone
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Contact> getContactName(Id contactId, String newValue) {
        return [
            SELECT
                Id,
                firstName,
                lastName
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Lead> getLeadEmailAddress(Id leadId, String newValue) {
        return [
            SELECT
                Id,
                Email
            FROM Lead
            WHERE Id = :leadId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
    @AuraEnabled(Cacheable=true)
    public static List<Lead> getLeadName(Id leadId, String newValue) {
        return [
            SELECT
                Id,
                firstName,
                lastName
                FROM Lead
                WHERE Id = :leadId
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
    }
}