/**
 * @description This utility gets the values dynamically using the uiRecordApi,
 *               Importing this file into other LWC's will provide contact record field values dynamically.
 * @param getRecord = uiRecordApi
 * @wire wire service provisions data to be used in callouts 
 */
 import { LightningElement, api, wire } from 'lwc';
 import { getRecord } from 'lightning/uiRecordApi';
 
 const FIELDS = [
     'Contact.Name',
     'Contact.Phone',
     'Contact.MobilePhone',
     'Contact.Email',
     'Contact.Secondary_Email__c',
 ];

export default class CdpRestOneView extends LightningElement {
    @api recordId;
    
    /**
     * @param recordId — ID of the record to retrieve.
     * @param fields
     * Object-qualified field API names to retrieve. If a field isn’t accessible to the context user, it causes an error. If specified, don't specify layoutTypes.
     */
    
    @wire(getRecord, {recordId: '$recordId', FIELDS})
    contact;
    
    getphone() {
        return this.contact.data.fields.Phone.value;
    }

    getMobilePhone() {
        return this.contact.data.fields.MobilePhone.value;
    }
    
    getEmail() {
        return this.contact.data.fields.Email.value;
    }
    
    getSecondaryEmail() {
        return this.contact.data.fields.Secondary_Email__c.value;
    }
    
    getName() {
        return this.contact.data.fields.Name.value;
    }

    getContactId() {
        return this.contact.data.fields.Id.value;
    }
   
}