/**
 * @description       :
 * @author            : BDirheimer
 * @group             :
 * @last modified on  : 09-14-2021
 * @last modified by  : BDirheimer
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   09-14-2021   BDirheimer   Initial Version
 **/
import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import adoptContactDetails from '@salesforce/apex/DisplayGlobalProfileController.adoptContactDetails';
import displayGlobalProfile from '@salesforce/apex/DisplayGlobalProfileController.displayGlobalProfile';

export default class DisplayGlobalProfile extends LightningElement {
  // = {"globalPartyId": "XYZ","firstName": "Arjita","lastName": "Arjita","IsLastUpdatedIn24Hours": true,"EmailContactPoints": [{"contactPointValue": "atest@test.com","ContactPointType": "Email","dataSourceName": "SAP, Siebel"},{"contactPointValue": "atest22@test.com","ContactPointType": "Email","dataSourceName": "Market Cloud, SAP"}],"PhoneContactPoints": [{"contactPointValue": "+9911223344","ContactPointType": "Home","dataSourceName": "SAP"}, {"contactPointValue": "+9911223884","ContactPointType": "Mobile","dataSourceName": "Market Cloud, SAP"}],"PartyIdentificationContactPoints" : [{"contactPointValue": "GovtNumber1223","ContactPointType": "Physician Registration Number","dataSourceName": "Market Cloud"}, {"contactPointValue": "HealthNumber999","ContactPointType": "Physician Registration Number","dataSourceName": "Siebel"}],"AddressContactPoints" : [{"addressLine1": "32,Street","cityName": "Pune","postalCode": "302022","stateProvinceCode": "Maharashtra","countryName": "India","DataSourceValue": "SAP"},{"addressLine1": "221B,Baker Street","cityName": "London","postalCode": "EC1A","countryName": "United Kingdom","DataSourceValue": "SalesCloud, Market Cloud"}]};
  globalProfileDetailWrapper;
  isRecordAvailable = false;
  isWaitingForData = false;
  isAdoptButtonDisabled = true;
  isError = false;

  errorMessage = '';
  @api recordId;
  @api objectApiName;
  CONSTANT = {
    ERROR_STATUS: 'Error',
    ERROR_MESSAGE_1: 'No Record Available for this ',
    ERROR_MESSAGE_2: ' in Customer 360 Global Profile Hub.',
    SUCCESS_STATUS: 'Success',
    RECORD_UPDATED: 'Record Updated',
    RECORD_NOT_UPDATED: 'Record Not Updated',
    GLOBAL_PARTY_ID_LABEL: 'Global Party ID',
    FULL_NAME_LABEL: 'Full Name',
    EMAIL_LABEL: 'Email',
    PHONE_LABEL: 'Phone',
    MOBILE_LABEL: 'Mobile',
    MAILING_LABEL: 'Mailing',
    SYNCADDRESS_FIELD: false,
    CONTACT_POINT_VALUE: 'ContactPointValue'
  };

  connectedCallback() {
    this.isWaitingForData = true;
    displayGlobalProfile({ recordId: this.recordId }).then((result) => {
      this.isWaitingForData = false;
      if (result.status == this.CONSTANT.ERROR_STATUS) {
        this.isRecordAvailable = false;
        this.isError = true;
        this.errorMessage = result.errorMessage;
      } else {
        this.globalProfileDetailWrapper = result;
        console.log('RES:: ', JSON.parse(JSON.stringify(result)));
        if (this.globalProfileDetailWrapper.globalPartyId == undefined) {
          this.isRecordAvailable = false;
          this.isError = true;
          this.errorMessage =
            this.CONSTANT.ERROR_MESSAGE_1 +
            this.objectApiName +
            this.CONSTANT.ERROR_MESSAGE_2;
        } else {
          this.isRecordAvailable = true;
        }
      }
    });
  }

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
    this.isAdoptButtonDisabled = true;
  }

  get doesPartyIdentificationExist() {
    if (
      this.globalProfileDetailWrapper.PartyIdentificationContactPoints.length ==
      0
    ) {
      return false;
    } else {
      return true;
    }
  }

  adoptContactDetails() {
    var adoptedEmailValue = '';
    var adoptedPhoneValue = '';
    var adoptedMobileValue = '';
    var adoptedAddressValue = '';
    if (this.selectedEmailIndex != undefined) {
      adoptedEmailValue = {
        ContactPointValue:
          this.globalProfileDetailWrapper.EmailContactPoints[
            this.selectedEmailIndex
          ].contactPointValue
      };
    }
    if (this.selectedPhoneIndex != undefined) {
      adoptedPhoneValue = {
        ContactPointValue:
          this.globalProfileDetailWrapper.PhoneContactPoints[
            this.selectedPhoneIndex
          ].contactPointValue,
        ContactPointType:
          this.globalProfileDetailWrapper.PhoneContactPoints[
            this.selectedPhoneIndex
          ].contactPointType
      };
    }
    if (this.selectedMobileIndex != undefined) {
      adoptedMobileValue = {
        ContactPointValue:
          this.globalProfileDetailWrapper.MobileContactPoints[
            this.selectedMobileIndex
          ].contactPointValue,
        ContactPointType:
          this.globalProfileDetailWrapper.MobileContactPoints[
            this.selectedMobileIndex
          ].contactPointType
      };
    }
    if (this.selectedAddressIndex != undefined) {
      adoptedAddressValue = {
        addressLine1:
          this.globalProfileDetailWrapper.AddressContactPoints[
            this.selectedAddressIndex
          ].addressLine1,
        cityName:
          this.globalProfileDetailWrapper.AddressContactPoints[
            this.selectedAddressIndex
          ].cityName,
        stateProvinceName:
          this.globalProfileDetailWrapper.AddressContactPoints[
            this.selectedAddressIndex
          ].stateProvinceName,
        //"MailingStateCode" : this.globalProfileDetailWrapper.AddressContactPoints[this.selectedAddressIndex].MailingStateCode,
        countryName:
          this.globalProfileDetailWrapper.AddressContactPoints[
            this.selectedAddressIndex
          ].countryName,
        postalCode:
          this.globalProfileDetailWrapper.AddressContactPoints[
            this.selectedAddressIndex
          ].postalCode
      };
    }
    var adoptedValuesJSON = {
      recordID: this.recordId,
      sObjectName: this.objectApiName,
      adoptedEmailValues: adoptedEmailValue == '' ? null : adoptedEmailValue,
      adoptedPhoneValues: adoptedPhoneValue == '' ? null : adoptedPhoneValue,
      adoptedMobileValues: adoptedMobileValue == '' ? null : adoptedMobileValue,
      adoptedAddressValues:
        adoptedAddressValue == '' ? null : adoptedAddressValue
    };
    adoptContactDetails({
      adoptDetailsJSON: JSON.stringify(adoptedValuesJSON)
    }).then((result) => {
      if (result == this.CONSTANT.SUCCESS_STATUS) {
        const evt = new ShowToastEvent({
          title: this.CONSTANT.SUCCESS_STATUS,
          message: this.CONSTANT.RECORD_UPDATED,
          variant: this.CONSTANT.SUCCESS_STATUS
        });
        this.dispatchEvent(evt);
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