/* eslint-disable vars-on-top */
/**
 * Created by bdirh on 12/27/2021.
 */

 import { LightningElement, api, track , wire} from 'lwc';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 //import getUnifiedProfile from '@salesforce/apex/CDP_DisplayUnifiedProfile.displayUnifiedProfile';
 import adoptContactDetails from '@salesforce/apex/CDP_DisplayUnifiedProfile.adoptContactDetails';
 import { getObjectInfo } from 'lightning/uiObjectInfoApi';
 import getCDPLead from '@salesforce/apex/CDPRestLWCController.getCDPLead';
 import getAllContactFields from '@salesforce/apex/CDPRestLWCController.getAllContactFields';
import validateObjects from '@salesforce/apex/CDPRestSearchFields.validateObjects';
// import CONTACT_OBJECT from '@schema/salesforce/Contact';
// import LEAD_OBJECT from '@schema/salesforce/Lead';


 /*SFSC-7001- Radiobutton disable*/
 //import { getRecord } from 'lightning/uiRecordApi';
 /*
 const FIELDS = ['Contact.Email', 
  'Contact.Phone',
  'Contact.MailingCity',
  'Contact.MailingCountry', 
  'Contact.MailingPostalCode',
  'Contact.MailingStateCode',
  'Contact.MailingStreet',
  'Contact.Secondary_Email__c',
  'Contact.MobilePhone'];
  */
 // eslint-disable-next-line no-unused-vars
 
 export default class DisplayUnifiedProfile extends LightningElement {
    /*SFSC-7001- Radiobutton disable*/
    
    @api recordId;
    @api objectApiName;
    @api CONTACT_FIELD;
    @api LEAD_FIELD;
    searchKey = '';
    contactData;
    contactEmail;
    contactPhone;
    contactMailingCity;
    contactMailingCountryCode;
    contactMailingPostalCode;
    contactMailingStateCode;
    contactMailingStreet;
    contactSecondary_Email__c;
    contactMobilePhone;

    

  // To fetch data from the Contact object for comparison.
  /*@wire(getRecord, { recordId: '$recordId', fields: FIELDS})
  wiredRecord({ error, data }) {
    if (error) {
  
             console.log('Received Error');
  
        }else if (data) {
          console.log('data is', data);
          this.contactData = data;
          this.contactEmail =   this.contactData.fields.Email.value;
          this.contactPhone =  this.contactData.fields.Phone.value;
          this.contactSecondary_Email__c = this.contactData.fields.Secondary_Email__c.value;
          this.contactMobilePhone =  this.contactData.fields.MobilePhone.value;
          this.contactMailingCity =  this.contactData.fields.MailingCity.value;
          this.contactMailingCountryCode =  this.contactData.fields.MailingCountry.value;
          this.contactMailingPostalCode =  this.contactData.fields.MailingPostalCode.value;
          this.contactMailingStateCode =  this.contactData.fields.MailingStateCode.value;
          this.contactMailingStreet =  this.contactData.fields.MailingStreet.value;
          if (this.contactMailingStreet === null){
              this.contactMailingStreet = "";
          }
          if (this.contactMailingStateCode === null){
              this.contactMailingStateCode = "";
          }
          if (this.contactMailingPostalCode === null){
              this.contactMailingPostalCode = "";
          }
          if (this.contactMailingCountryCode === null){
              this.contactMailingCountryCode = "";
          }
          if (this.contactMailingCity === null){
              this.contactMailingCity = "";
          }

        }
      }  */

      parmObject = {
          responseObject: this.searchKey
      };
      
/**
 * Decorator factory to wire a property or method to a wire adapter data source
 * @param getType — imperative accessor for the data source
 * @param config — configuration object for the accessor => Bound to an object to access later
 */
      
    @wire(validateObjects, { searchObject: '$parmObject' })
    respObject;      
    }

    @wire()

        hangleChange(event) {
            this.parmObject = {
                ...this.parmObject,
                searchObject: (this.searchKey = event.target.value)
            }
        }

     /**
       * (method) Function.bind(this: Function, thisArg: any, ...argArray: any[]): any
       * For a given function, creates a bound function that has the same body as the 
       * original function. The this object of the bound function is associated with the 
       * specified object, and has the specified initial parameters.
       * @param thisArg — An object to which the this keyword can refer inside the new function.
       * @param argArray — objectApiName
       */

    get objectInfoStr() {
        JSON.stringify(this.objectInfo.data, null, 2) 
        Object.assign(this.recordId, JSON)
    };

     unifiedProfileDetailWrapper;
     isRecordAvailable = false;
     isWaitingForData = false;
     mobileContactPointsAvailable = false;
     phoneContactPointsAvailable = false;
     emailContactPointsAvailable = false;
     addressContactPointsAvailable = false;
     secondaryEmailContactPointsAvailable = false;
     isAdoptButtonDisabled = true;
     isError = false;
 
     errorMessage = '';

     @wire(validateObjects, { responseObject}
     
     @api objectApiName;
     CONSTANT = {
         ERROR_STATUS: 'Error',
         ERROR_MESSAGE_1: true,
         ERROR_MESSAGE_2: ' in Customer Data Platfom.',
         SUCCESS_STATUS: 'Success',
         RECORD_UPDATED: 'Record Updated',
         RECORD_NOT_UPDATED: 'Record Not Updated',
         UPID_LABEL: 'Unified Profile Id',
         FULL_NAME_LABEL: 'Full Name',
         EMAIL_LABEL: 'Email',
         SECONDARY_EMAIL_LABEL: 'Secondary Email',
         PHONE_LABEL: 'Phone',
         MOBILE_LABEL: 'Mobile',
         MAILING_LABEL: 'Mailing',
         SYNCADDRESS_FIELD: false,
         CONTACT_POINT_VALUE: 'ContactPointValue'
     };
 
     @track emailContactPointsList = [];
 
 //Data will be fetched from CDP and compare with Contact data retrived.
 /*
     connectedCallback() {
         this.isWaitingForData = true;
         getUnifiedProfile({ recordId: this.recordId }).then((result) => {
             this.isWaitingForData = false;
             if (result.status === this.CONSTANT.ERROR_STATUS) {
                 this.isRecordAvailable = false;
                 this.isError = true;
                 this.errorMessage = result.errorMessage;
             } else {
                 var unifiedProfileData = result;       /*SFSC-7001- Radiobutton disable
                 */                         
         /*        this.unifiedProfileDetailWrapper = JSON.parse(JSON.stringify(unifiedProfileData)); /*SFSC-7001- Radiobutton disable*/
 
                 //this.unifiedProfileDetailWrapper = result;                
       /*          if (this.unifiedProfileDetailWrapper.UPId === undefined) {
                     this.isRecordAvailable = false;
                     this.isError = true;
                     this.errorMessage =
                         this.CONSTANT.ERROR_MESSAGE_1 +
                         this.objectApiName +
                         this.CONSTANT.ERROR_MESSAGE_2;
                 } else {
                     this.isRecordAvailable = true;
                     Object.assign({}, this.contactDetailData) /*SFSC-7001- Radiobutton disable 
                     if (
                         this.unifiedProfileDetailWrapper.MobileContactPoints
                             .length > 0
                     ) {
                         this.mobileContactPointsAvailable = true;
                     }
                     if (
                         this.unifiedProfileDetailWrapper.PhoneContactPoints
                             .length > 0
                     ) {
                         this.phoneContactPointsAvailable = true;
                     }
                     if (
                         this.unifiedProfileDetailWrapper.EmailContactPoints
                             .length > 0
                     ) {
                         this.emailContactPointsAvailable = true;
                     }
                     if (
                         this.unifiedProfileDetailWrapper
                             .SecondaryEmailContactPoints.length > 0
                     ) {
                         this.secondaryEmailContactPointsAvailable = true;
                     }
                     if (
                         this.unifiedProfileDetailWrapper.AddressContactPoints
                             .length > 0
                     ) {
                         this.addressContactPointsAvailable = true;
                     } 
                 /*SFSC-7001- Radiobutton disable - starts 
                 console.log('contactInfo'+contactInfo.data);  
                     var emailContactPoints = this.unifiedProfileDetailWrapper.EmailContactPoints;
                     emailContactPoints.forEach(profileEmail =>{
                         if(profileEmail.contactPointValue === this.contactEmail){
                             profileEmail.isEmailAvailable = true;
                         }else{
                             profileEmail.isEmailAvailable = false;
                         }
                     })
 
                       var secondaryEmailContactPoints = this.unifiedProfileDetailWrapper.SecondaryEmailContactPoints;
                       secondaryEmailContactPoints.forEach(profileSecEmail => {
                                   if(profileSecEmail.contactPointValue === this.contactSecondary_Email__c){
                                    profileSecEmail.isSecondaryEmailAvailable = true;
                                   }else{
                                     profileSecEmail.isSecondaryEmailAvailable = false;
                                   }
                               })
 
         
                       var mobileContactPoints = this.unifiedProfileDetailWrapper.MobileContactPoints;
                       mobileContactPoints.forEach(profileMobilePhone => {
                                     if(profileMobilePhone.contactPointValue === this.contactMobilePhone){
                                       profileMobilePhone.isMobilePhoneAvailable = true;
                                     }else{
                                     profileMobilePhone.isMobilePhoneAvailable = false;
                                     }
                                 })
 
         
                         var phoneContactPoints = this.unifiedProfileDetailWrapper.PhoneContactPoints;
                         phoneContactPoints.forEach(profilePhone =>{
                                     if(profilePhone.contactPointValue === this.contactPhone){
                                       profilePhone.isPhoneAvailable = true;
                                     }else{
                                       profilePhone.isPhoneAvailable = false;
                                     }
                                 })
         
                         var addressContactPoints = this.unifiedProfileDetailWrapper.AddressContactPoints;
                         addressContactPoints.forEach(profileAddress =>{
                         if(profileAddress.addressLine1 === this.contactMailingStreet && profileAddress.cityName === this.contactMailingCity && profileAddress.stateProvinceName === this.contactMailingStateCode && profileAddress.countryName === this.contactMailingCountryCode && profileAddress.postalCode === this.contactMailingPostalCode){
                           profileAddress.isAddressAvailable = true;
                         }else{
                           profileAddress.isAddressAvailable = false;
                         }
                         })
                              
                 }
                 /*SFSC-7001- Radiobutton disable - ends
             }
         })
         .catch((error) => {
             this.isWaitingForData = false;
             this.isRecordAvailable = false;
                 this.isError = true;
                 console.log('error--'+error);
             this.errorMessage = 'There is some error in finding data for this record, Contact your administrator!!';               
         });
     }
 // Below meathods will read the data from index on changing
     selectAddressRecordIndex(event) {
         this.isAdoptButtonDisabled = false;
         this.selectedAddressIndex = event.target.dataset.value;
     }
     selectPhoneRecordIndex(event) {
         this.isAdoptButtonDisabled = false;
         this.selectedPhoneIndex = event.target.dataset.value;
     }
     selectMobileRecordIndex(event) {
         this.isAdoptButtonDisabled = false;
         this.selectedMobileIndex = event.target.dataset.value;
     }
     selectEmailRecordIndex(event) {
         this.isAdoptButtonDisabled = false;
         this.selectedEmailIndex = event.target.dataset.value;
     }
     selectSecondaryEmailRecordIndex(event) {
         this.isAdoptButtonDisabled = false;
         this.selectedSecondaryEmailIndex = event.target.dataset.value;
     }
     resetRadioButton() {
         var radioDeselectElement = this.template.querySelectorAll(
             'lightning-input[data-name="radio-deselect"]'
         );
 
         for (var i = 0; i < radioDeselectElement.length; i++) {
             radioDeselectElement[i].checked = false;
         }
         this.selectedEmailIndex = undefined;
         this.selectedAddressIndex = undefined;
         this.selectedPhoneIndex = undefined;
         this.selectedMobileIndex = undefined;
         this.selectedSecondaryEmailIndex = undefined;
         this.isAdoptButtonDisabled = true;
     }
 
     get doesPartyIdentificationExist() {
         return (
             typeof this.doesPartyIdentificationExist ===
             this.unifiedProfileDetailWrapper.PartyIdentificationContactPoints
         );
     }
     /*
      if (
        this.unifiedProfileDetailWrapper.PartyIdentificationContactPoints
          .length == 0
      ) {
        return false;
      } else {
        return true;
      }
    }
  */
  // takes the adopted details on seleting and clicking the adopt button and update the contact data accordingly
     adoptContactDetails() {
         this.isWaitingForData = true;
         var adoptedEmailValue = '';
         var adoptedSecondaryEmailValue = '';
         var adoptedPhoneValue = '';
         var adoptedMobileValue = '';
         var adoptedAddressValue = '';
         if (this.selectedEmailIndex !== undefined) {
             adoptedEmailValue = {
                 ContactPointValue:
                     this.unifiedProfileDetailWrapper.EmailContactPoints[
                         this.selectedEmailIndex
                     ].contactPointValue
             };
         }
         if (this.selectedSecondaryEmailIndex !== undefined) {
             adoptedSecondaryEmailValue = {
                 ContactPointValue:
                     this.unifiedProfileDetailWrapper
                         .SecondaryEmailContactPoints[
                         this.selectedSecondaryEmailIndex
                     ].contactPointValue
             };
         }
         if (this.selectedPhoneIndex !== undefined) {
             adoptedPhoneValue = {
                 ContactPointValue:
                     this.unifiedProfileDetailWrapper.PhoneContactPoints[
                         this.selectedPhoneIndex
                     ].contactPointValue,
                 ContactPointType:
                     this.unifiedProfileDetailWrapper.PhoneContactPoints[
                         this.selectedPhoneIndex
                     ].contactPointType
             };
         }
         if (this.selectedMobileIndex !== undefined) {
             adoptedMobileValue = {
                 ContactPointValue:
                     this.unifiedProfileDetailWrapper.MobileContactPoints[
                         this.selectedMobileIndex
                     ].contactPointValue,
                 ContactPointType:
                     this.unifiedProfileDetailWrapper.MobileContactPoints[
                         this.selectedMobileIndex
                     ].contactPointType
             };
         }
         if (this.selectedAddressIndex !== undefined) {
             adoptedAddressValue = {
                 addressLine1:
                     this.unifiedProfileDetailWrapper.AddressContactPoints[
                         this.selectedAddressIndex
                     ].addressLine1,
                 cityName:
                     this.unifiedProfileDetailWrapper.AddressContactPoints[
                         this.selectedAddressIndex
                     ].cityName,
                 stateProvinceName:
                     this.unifiedProfileDetailWrapper.AddressContactPoints[
                         this.selectedAddressIndex
                     ].stateProvinceName,
                 countryName:
                     this.unifiedProfileDetailWrapper.AddressContactPoints[
                         this.selectedAddressIndex
                     ].countryName,
                 postalCode:
                     this.unifiedProfileDetailWrapper.AddressContactPoints[
                         this.selectedAddressIndex
                     ].postalCode
             };
         }
         var adoptedValuesJSON = {
             recordID: this.recordId,
             sObjectName: this.objectApiName,
             adoptedEmailValues:
                 adoptedEmailValue === '' ? null : adoptedEmailValue,
             adoptedSecondaryEmailValues:
                 adoptedSecondaryEmailValue === ''
                     ? null
                     : adoptedSecondaryEmailValue,
             adoptedPhoneValues:
                 adoptedPhoneValue === '' ? null : adoptedPhoneValue,
             adoptedMobileValues:
                 adoptedMobileValue === '' ? null : adoptedMobileValue,
             adoptedAddressValues:
                 adoptedAddressValue === '' ? null : adoptedAddressValue
         };
         adoptContactDetails({
             adoptDetailsJSON: JSON.stringify(adoptedValuesJSON)
         }).then((result) => {
             this.isWaitingForData = false;
             if (result === this.CONSTANT.SUCCESS_STATUS) {
                 const evt = new ShowToastEvent({
                     title: this.CONSTANT.SUCCESS_STATUS,
                     message: this.CONSTANT.RECORD_UPDATED,
                     variant: this.CONSTANT.SUCCESS_STATUS
                 });
                 this.dispatchEvent(evt);
                 eval("$A.get('e.force:refreshView').fire();");
             } else {
                 const evt = new ShowToastEvent({
                     title: this.CONSTANT.ERROR_STATUS,
                     message: this.CONSTANT.RECORD_NOT_UPDATED + ' - ' + result,
                     variant: this.CONSTANT.ERROR_STATUS
                 });
                 this.dispatchEvent(evt);
             }
             this.resetRadioButton();
         });
     }
 }