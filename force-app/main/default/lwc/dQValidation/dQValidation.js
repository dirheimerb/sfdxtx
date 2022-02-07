import { LightningElement, track, api } from "lwc";
import getDQMetadata from "@salesforce/apex/C360DMContactCreateController.getDQMetadata";
import DQValidateAddress from "@salesforce/apex/ContactValidationAPICallout.contactAddressValidation";
import DQValidateEmail from "@salesforce/apex/ContactValidationAPICallout.validateEmail";
import DQValidatePhone from "@salesforce/apex/ContactValidationAPICallout.validatePhoneNumber";

/*//SFSC - 6173  Detailed description of values used on Common DQ Validation component

DQ_CALLOUT - This is used to check if we get valid data from DQ and to display success toast message 
invalidData - This is used to check if we get invalid data from DQ and to display warning toast message
APIException - This is used to check if we get any API Exception 
isPrimaryEmail  - This is used to check if email is primary
isSecondaryEmail - This is used to check if email is secondary
isPhone - This is used to check if phone is phone 
isMobile  - This is used to check if phone is mobile phone
exceptionAddress  - This is used to check if there is any exception from DQ Address API
exceptionEmail - This is used to check if there is any exception from DQ Email API
exceptionPhone - This is used to check if there is any exception from DQ Phone API


********User stories for DQ API status value***********
https://wlgore.atlassian.net/browse/CPINS-7 - DQ Services: Real-Time Address Validation
https://wlgore.atlassian.net/browse/CPINS-6 - DQ Services: Real-Time Email 
https://wlgore.atlassian.net/browse/CPINS-8 - DQ Services: Real-Time Phone Validation
*/

export default class DQValidation extends LightningElement {
  @api contactDetailData = {};
  @api recordId;
  contactData = {};
  existingContactData = {};
  isMobileValidationCallbackReceived = false;
  isPhoneValidationCallbackReceived = false;
  isEmailValidationCallbackReceived = false;
  isSecondaryEmailValidationCallbackReceived = false;
  isAddressValidationCallbackReceived = false;
  emailResponss = {};
  phoneResponss = {};
  emailCheck = "";
  @track phoneModalType_Invalid = false;
  @track showModal_Invalid = false;
  @track invalidDataLists = [];
  @track phoneNumberTypeDataLists = [];
  showSuccessMsgEmail = "Email";
  showSuccessMsgSecondaryEmail = "SecondaryEmail";
  showSuccessMsgPhone = "Phone";
  showSuccessMsgAddress = "Address";
  showSuccessMsgMobilePhone = "Mobile";
  selectedAddressSelectionType = "";
  @api dqFieldToValidates = [];
  LABEL = {
    Verified_Valid: "Verified - Valid",
    Verified_Questionable: "Verified - Questionable",
    Unable_to_Process: "Unable to Process",
    Verified_Invalid: "Verified - Invalid",
    Verified_Ext_Invalid: "Verified - Ext Invalid",
    Read_timed_out: "Read timed out",
    Email: "Email",
    SecondaryEmail: "SecondaryEmail",
    Phone: "Phone",
    Mobile: "Mobile",
    Address: "Address",
    invalidEmail: "invalidEmail",
    invalidAddress: "invalidAddress",
    invalidSecondaryEmail: "invalidSecondaryEmail",
    invalidPhone: "invalidPhone",
    invalidMobile: "invalidMobile",
  };
  @api validateDQServices(selectedAddressSelectionType) {
    try {
      //this.isSpinner = true;
      // this.resetAll();
      //SFSC - 6173 - resetting the list because mobile, phone , email,secondary email and address wre displayed twice- starts
      this.resetALL();
      //SFSC - 6173 - resetting the list because mobile, phone , email,secondary email and address wre displayed twice- starts

      this.contactData = Object.assign({}, this.contactDetailData);
      this.selectedAddressSelectionType = selectedAddressSelectionType;
      let email = this.contactDetailData.Email;
      let secondaryEmail = this.contactDetailData.Secondary_Email__c;
      let phone = this.contactDetailData.Phone;
      let mobilePhone = this.contactDetailData.MobilePhone;

      //Killer switch for DQ - starts
      getDQMetadata()
        .then((result) => {
          let DQMetetadataRecords = result;
          DQMetetadataRecords.forEach((t) => {
            if (t.DeveloperName == "Email_Validation") {
              //validate primary email
              console.log("**0007", t);
              if (
                t.DQ_Service_On__c &&
                this.dqFieldToValidates.includes("Email")
              ) {
                console.log("**72", t);
                this.DQValidationEmail(email, "isPrimaryEmail");
              } else {
                this.isEmailValidationCallbackReceived = true;
                if (this.isEmptyOrNull(email)) {
                  this.contactData.Email_Verification_Status__c = null;
                  this.contactData.Email_Verification_Date__c = null;
                }
              }

              //validate secondary email
              if (
                t.DQ_Service_On__c &&
                this.dqFieldToValidates.includes("SecondaryEmail")
              ) {
                this.DQValidationEmail(secondaryEmail, "isSecondaryEmail");
              } else {
                this.isSecondaryEmailValidationCallbackReceived = true;
                if (this.isEmptyOrNull(secondaryEmail)) {
                  this.contactData.Secondary_Email_Verification_Status__c =
                    null;
                  this.contactData.Secondary_Email_Verification_Date__c = null;
                }
              }
            } else if (t.DeveloperName == "Phone_Validation") {
              //validate phone
              if (
                t.DQ_Service_On__c &&
                this.dqFieldToValidates.includes("Phone")
              ) {
                this.DQValidationPhone(phone, "isPhone");
              } else {
                this.isPhoneValidationCallbackReceived = true;
                if (this.isEmptyOrNull(phone)) {
                  this.contactData.Phone_Verification_Status__c = null;
                  this.contactData.Phone_Verification_Date__c = null;
                }
              }

              //validate mobile phone
              if (
                t.DQ_Service_On__c &&
                this.dqFieldToValidates.includes("MobilePhone")
              ) {
                this.DQValidationPhone(mobilePhone, "isMobile");
              } else {
                this.isMobileValidationCallbackReceived = true;
                if (this.isEmptyOrNull(mobilePhone)) {
                  this.contactData.Mobile_Phone_Verification_Status__c = null;
                  this.contactData.Mobile_Phone_Verification_Date__c = null;
                }
              }
            } else if (t.DeveloperName == "Address_Validation") {
              let newAddress =
                this.contactDetailData.MailingStreet +
                this.contactDetailData.MailingCity +
                this.contactDetailData.MailingCountryCode +
                this.contactDetailData.MailingStateCode +
                this.contactDetailData.MailingStateCode;
              // Added on 4 Aug, 2021 - fixed address issue
              if (this.dqFieldToValidates.includes("Address")) {
                if (t.DQ_Service_On__c) {
                  this.DQValidationAddress();
                } else {
                  // Added on 18 Aug, 2021 - fixed blank address issue
                  this.isAddressValidationCallbackReceived = true;
                  if (this.isEmptyOrNull(newAddress)) {
                    this.contactData.Address_Verification_Status__c = null;
                    this.contactData.Address_Verification_Date__c = null;
                  }
                }
              } else {
                this.isAddressValidationCallbackReceived = true;
                if (this.isEmptyOrNull(newAddress)) {
                  this.contactData.Address_Verification_Status__c = null;
                  this.contactData.Address_Verification_Date__c = null;
                }
              }
            }
          });
        })
        .catch((error) => {
          this.isAddressValidationCallbackReceived = true;
          this.isEmailValidationCallbackReceived = true;
          this.isMobileValidationCallbackReceived = true;
          this.isPhoneValidationCallbackReceived = true;
          this.isSecondaryEmailValidationCallbackReceived = true;
        });
      //Killer switch for DQ - ends

      var checkAllResponse = window.setInterval(() => {
        if (
          this.isMobileValidationCallbackReceived &&
          this.isPhoneValidationCallbackReceived &&
          this.isEmailValidationCallbackReceived &&
          this.isSecondaryEmailValidationCallbackReceived &&
          this.isAddressValidationCallbackReceived
        ) {
          //show Success Message - starts
          if (
            this.showSuccessMsgAddress == this.LABEL.Address &&
            this.showSuccessMsgEmail == this.LABEL.Email &&
            this.showSuccessMsgPhone == this.LABEL.Phone &&
            this.showSuccessMsgSecondaryEmail == this.LABEL.SecondaryEmail &&
            this.showSuccessMsgMobilePhone == this.LABEL.Mobile
          ) {
            // clear interval
            window.clearInterval(checkAllResponse);
            this.contactData.inValidData = "DQ_CALLOUT";
            // pass data to parent component
            this.passDataToParent();
            //this.showCorrectDataToastMessage();
          } else if (
            this.showSuccessMsgPhone == this.LABEL.invalidPhone ||
            this.showSuccessMsgMobilePhone == this.LABEL.invalidMobile ||
            this.showSuccessMsgEmail == this.LABEL.invalidEmail ||
            this.showSuccessMsgSecondaryEmail ==
              this.LABEL.invalidSecondaryEmail ||
            this.showSuccessMsgAddress == this.LABEL.invalidAddress
          ) {
            //to stop spinner when invalid modal is displayed and save invalid data
            if (this.invalidDataLists.length > 0) {
              this.showModal_Invalid = this.showModal_Invalid || true;
              this.isInvalidListEmpty = false;
            }
            if (this.phoneNumberTypeDataLists.length > 0) {
              if (this.invalidDataLists.length == 0) {
                this.isInvalidListEmpty = true;
              }
              this.showModal_Invalid = this.showModal_Invalid || true;
            }
          } else if (
            this.showSuccessMsgAddress == "exceptionAddress" ||
            this.showSuccessMsgEmail == "exceptionEmail" ||
            this.showSuccessMsgPhone == "exceptionPhone"
          ) {
            // clear interval
            window.clearInterval(checkAllResponse);

            this.contactData.inValidData = "APIException";
            // pass data to parent component
            this.passDataToParent();
          }
          //show Success Message - ends
          //clear the interval
        }
      }, 1000);
    } catch (error) {
      console.log("error " + error);
    }
  }

  DQValidationEmail(email, emailCheck) {
    DQValidateEmail({ emailName: email, recordId: this.recordId })
      .then((result) => {
        console.log("**200");
        let emailResponss = result;
        this.emailResponss = emailResponss;
        if (emailResponss.statusDescription != null) {
          if (emailCheck == "isPrimaryEmail") {
            if (email != null) {
              this.DQVerifyPrimaryEmail(emailResponss);
            }
          }

          if (email != null) {
            if (emailCheck == "isSecondaryEmail") {
              this.DQVerifySecondaryEmail(emailResponss);
            }
          }
        }
        // set the callback flag for email
        if (emailCheck == "isPrimaryEmail")
          this.isEmailValidationCallbackReceived = true;
        if (emailCheck == "isSecondaryEmail")
          this.isSecondaryEmailValidationCallbackReceived = true;

        //handle exception
        if (emailResponss.exceptionMessage != null) {
          this.showSuccessMsgEmail = "exceptionEmail";
        }
      })
      .catch((error) => {
        this.isEmailValidationCallbackReceived = true;
        this.isSecondaryEmailValidationCallbackReceived = true;
        this.showSuccessMsgEmail = "exceptionEmail";
      });
  }

  DQValidationPhone(phone, phoneCheck) {
    DQValidatePhone({
      phoneNumber: phone,
      recordId: this.recordId,
      MailingCountryCode: this.contactDetailData.MailingCountryCode,
    })
      .then((result) => {
        this.phoneResponss = result;
        var phoneResponss = this.phoneResponss;
        if (phoneResponss.statusDescription != null) {
          if (phoneCheck == "isPhone") {
            if (phone != null) {
              this.DQVerifyPhone(phoneResponss);
            }
          }
          if (phoneCheck == "isMobile") {
            if (phone != null) {
              this.DQVerifyMobilePhone(phoneResponss);
            }
          }
        }
        // set the callback flag for phone
        if (phoneCheck == "isPhone")
          this.isPhoneValidationCallbackReceived = true;
        if (phoneCheck == "isMobile")
          this.isMobileValidationCallbackReceived = true;

        //handle exception
        if (phoneResponss.exceptionMessage != null) {
          this.showSuccessMsgPhone = "exceptionPhone";
        }
        //this.isSpinner = false;
      })
      .catch((error) => {
        this.isPhoneValidationCallbackReceived = true;
        this.isMobileValidationCallbackReceived = true;
        this.showSuccessMsgPhone = "exceptionPhone";
      });
  }

  // Address DQ Method is Called
  DQValidationAddress() {
    let addressLine1, addressLine2, addressLine3, addressLine4, mailingStreet;
    if (this.isNotBlank(this.contactDetailData.MailingStreet)) {
      mailingStreet = this.contactDetailData.MailingStreet.split("\n");
      addressLine1 = mailingStreet[0];
      addressLine2 = mailingStreet[1] == undefined ? "" : mailingStreet[1];
      addressLine3 = mailingStreet[2] == undefined ? "" : mailingStreet[2];
      addressLine4 = mailingStreet[3] == undefined ? "" : mailingStreet[3];
      if (mailingStreet.length > 4) {
        for (let i = 4; i < mailingStreet.length; i++) {
          addressLine4 = addressLine4 + " " + mailingStreet[i];
        }
      }
    }

    console.log("OUTPUT : ");
    DQValidateAddress({
      address1: addressLine1 == null ? "" : addressLine1,
      address2: addressLine2 == null ? "" : addressLine2,
      address3: addressLine3 == null ? "" : addressLine3,
      address4: addressLine4 == null ? "" : addressLine4,
      cityName:
        this.contactDetailData.MailingCity == undefined
          ? ""
          : this.contactDetailData.MailingCity,
      stateName:
        this.contactDetailData.MailingStateCode == undefined
          ? ""
          : this.contactDetailData.MailingStateCode,
      zipCode:
        this.contactDetailData.MailingPostalCode == undefined
          ? ""
          : this.contactDetailData.MailingPostalCode,
      countryName:
        this.contactDetailData.MailingCountryCode == undefined
          ? ""
          : this.contactDetailData.MailingCountryCode,
      timeOut: null,
    })
      .then((result) => {
        console.log("RES : ", JSON.parse(JSON.stringify(result)));
        if (result.status.includes("Error")) {
          this.showSuccessMsgAddress = "exceptionAddress";
        } else {
          var today = this.formatDate(this.calculateTodaysDate());
          if (
            result.status == "valid" ||
            result.status == this.LABEL.Verified_Questionable ||
            result.status == this.LABEL.Verified_Valid
          ) {
            this.showSuccessMsgAddress = this.LABEL.Address;
          } else if (result.status == this.LABEL.Verified_Invalid) {
            this.invalidDataLists.push("Mailing Address");
            this.showSuccessMsgAddress = this.LABEL.invalidAddress;
          }
          //Added on 7 Oct 2021
          this.contactData.Address_Verification_Status__c = result.status;
          this.contactData.Address_Verification_Date__c = today;
        }
        this.isAddressValidationCallbackReceived = true;
      })
      .catch((error) => {
        this.isAddressValidationCallbackReceived = true;
        this.showSuccessMsgAddress = "exceptionAddress";
      });
  }

  DQVerifyPrimaryEmail(emailResponss) {
    var today = this.formatDate(this.calculateTodaysDate());
    if (
      emailResponss.statusDescription == this.LABEL.Verified_Valid ||
      emailResponss.statusDescription == this.LABEL.Verified_Questionable ||
      emailResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.contactData.Email_Verification_Status__c =
        emailResponss.statusDescription;
      this.contactData.Email_Verification_Date__c = today;
      this.showSuccessMsgEmail = this.LABEL.Email;
    } else if (emailResponss.statusDescription == this.LABEL.Verified_Invalid) {
      this.contactData.Email_Verification_Status__c =
        emailResponss.statusDescription;
      this.contactData.Email_Verification_Date__c = today;
      this.invalidDataLists.push("Email");
      this.showSuccessMsgEmail = this.LABEL.invalidEmail;
    }
  }
  DQVerifySecondaryEmail(emailResponss) {
    var today = this.formatDate(this.calculateTodaysDate());
    if (
      emailResponss.statusDescription == this.LABEL.Verified_Valid ||
      emailResponss.statusDescription == this.LABEL.Verified_Questionable ||
      emailResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.contactData.Secondary_Email_Verification_Status__c =
        emailResponss.statusDescription;
      this.contactData.Secondary_Email_Verification_Date__c = today;
      this.showSuccessMsgSecondaryEmail = this.LABEL.SecondaryEmail;
    } else if (emailResponss.statusDescription == this.LABEL.Verified_Invalid) {
      this.contactData.Secondary_Email_Verification_Status__c =
        emailResponss.statusDescription;
      this.contactData.Secondary_Email_Verification_Date__c = today;
      this.invalidDataLists.push("Secondary Email");
      this.showSuccessMsgSecondaryEmail = this.LABEL.invalidSecondaryEmail;
    }
  }
  DQVerifyPhone(phoneResponss) {
    var today = this.formatDate(this.calculateTodaysDate());
    if (
      phoneResponss.statusDescription == this.LABEL.Verified_Valid ||
      phoneResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgPhone = this.LABEL.Phone;
    }

    if (phoneResponss.numberType == this.LABEL.Mobile) {
      this.phoneModalType_Invalid = this.phoneModalType_Invalid || true;
      this.phoneNumberTypeDataLists.push("Phone - Please move to mobile");
      this.showSuccessMsgPhone = this.LABEL.invalidPhone;
    } else if (
      phoneResponss.statusDescription == this.LABEL.Verified_Invalid ||
      phoneResponss.statusDescription == this.LABEL.Verified_Ext_Invalid
    ) {
      this.phoneModalType_Invalid = this.phoneModalType_Invalid || false;
      this.invalidDataLists.push("Phone");
      this.showSuccessMsgPhone = this.LABEL.invalidPhone;
    }

    this.contactData.Phone_Verification_Status__c =
      phoneResponss.statusDescription;
    this.contactData.Phone_Verification_Date__c = today;
  }

  DQVerifyMobilePhone(phoneResponss) {
    var today = this.formatDate(this.calculateTodaysDate());
    if (
      phoneResponss.statusDescription == this.LABEL.Verified_Valid ||
      phoneResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgMobilePhone = this.LABEL.Mobile;
    }
    if (phoneResponss.numberType == this.LABEL.Landline) {
      this.phoneModalType_Invalid = this.phoneModalType_Invalid || true;
      this.phoneNumberTypeDataLists.push("Mobile - Please move to phone");
      this.showSuccessMsgMobilePhone = this.LABEL.invalidMobile;
    } else if (
      phoneResponss.statusDescription == this.LABEL.Verified_Invalid ||
      phoneResponss.statusDescription == this.LABEL.Verified_Ext_Invalid
    ) {
      this.phoneModalType_Invalid = this.phoneModalType_Invalid || false;
      this.invalidDataLists.push("Mobile");
      this.showSuccessMsgMobilePhone = this.LABEL.invalidMobile;
    }

    this.contactData.Mobile_Phone_Verification_Status__c =
      phoneResponss.statusDescription;
    this.contactData.Mobile_Phone_Verification_Date__c = today;
  }
  handleNo() {
    this.showModal_Invalid = false;
    this.phoneModalType_Invalid = false;
    this.contactData.inValidData = "invalidData";
    this.closeDQModal();
    this.passDataToParent();
    this.resetALL(); //SFSC - 6173 - for resetting the list
  }
  handleYes() {
    this.showModal_Invalid = false;
    this.phoneModalType_Invalid = false;
    this.closeDQModal();
    this.resetALL(); //SFSC - 6173 - for resetting the list
  }

  formatDate(date) {
    let d = new Date(date),
      month = "" + (d.getMonth() + 1),
      day = "" + d.getDate(),
      year = d.getFullYear();

    if (month.length < 2) month = "0" + month;
    if (day.length < 2) day = "0" + day;

    return [year, month, day].join("-");
  }
  calculateTodaysDate() {
    //calculate today's date
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth() + 1;
    var yyyy = today.getFullYear();

    today = yyyy + "-" + mm + "-" + dd;
    return today;
  }

  passDataToParent() {
    const contactDataUpdated = new CustomEvent("contactdataupdated", {
      detail: this.contactData,
    });

    // Dispatches the event.
    this.dispatchEvent(contactDataUpdated);
  }

  closeDQModal() {
    const closeDQModalPopup = new CustomEvent("closedqmodalpopup", {
      detail: this.showModal_Invalid,
    });

    // Dispatches the event.
    this.dispatchEvent(closeDQModalPopup);
  }

  isNotBlank(value) {
    return value != null && value != "" && value.trim().length > 0;
  }
  isEmptyOrNull(value) {
    return value == null || value == "";
  }
  //SFSC - 6173 -starts
  resetALL() {
    this.isAddressValidationCallbackReceived = false;
    this.isEmailValidationCallbackReceived = false;
    this.isSecondaryEmailValidationCallbackReceived = false;
    this.isMobileValidationCallbackReceived = false;
    this.isPhoneValidationCallbackReceived = false;
    this.phoneNumberTypeDataLists = [];
    this.invalidDataLists = [];
  }
  //SFSC - 6173 - ends
}
