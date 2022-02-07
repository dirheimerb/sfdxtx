import { LightningElement, api, wire, track } from "lwc";

import CONTACT_OBJECT from "@salesforce/schema/Contact";
import {
  getObjectInfo,
  getPicklistValues,
  getPicklistValuesByRecordType,
} from "lightning/uiObjectInfoApi";
import { getRecordUi, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import MAILING_COUNTRY_FIELD from "@salesforce/schema/Contact.MailingCountryCode";
import MAILING_STATE_FIELD from "@salesforce/schema/Contact.MailingStateCode";
import { NavigationMixin } from "lightning/navigation";
import DQValidateAddress from "@salesforce/apex/ContactValidationAPICallout.contactAddressValidation";
import DQValidateEmail from "@salesforce/apex/ContactValidationAPICallout.validateEmail";
import DQValidatePhone from "@salesforce/apex/ContactValidationAPICallout.validatePhoneNumber";
import getDQMetadata from "@salesforce/apex/C360DMContactCreateController.getDQMetadata";
const DEFAULT_PICKLIST_VALUE = { label: "--None--", value: "none" };

import updateDuplicateContact from "@salesforce/apex/C360DMContactCreateController.updateDuplicateContact";
import EmailBouncedDate from "@salesforce/schema/Contact.EmailBouncedDate";
import { loadScript } from "lightning/platformResourceLoader";
import updateCompactSettings from "@salesforce/resourceUrl/densitySettings";

export default class ContactDetails extends NavigationMixin(LightningElement) {
  @api recordId;
  @api isEditModalWindow = false;
  @api isEditMode = false;
  isViewMode = true;
  isSaveAndNewButton = false;
  @track layoutSections = [];
  activeSections = [];
  headingSections = [];
  isViewAllDependentModal = false;
  jobFunctionOptions = [DEFAULT_PICKLIST_VALUE];
  physicianIndependenceOptions = [];
  recordTypeId;
  fieldApiName;
  isAddressChanged = false;
  isMobileChanged = false;
  isPhoneChanged = false;
  isEmailChanged = false;
  isSecondaryEmailChanged = false;
  mapMarkers;
  allMailingStates;
  @track sectionLabel = "Show";
  @track buttonVisible = false;
  @track isNameLabel = false;
  @track isSpinner = false; // Added on 28/7/2021
  recordData;
  updatedContactDetail = {};
  updatedAddressDetails = {};

  mailingCountries = [];
  mailingStates = [];
  isMobileValidationCallbackReceived = false;
  isPhoneValidationCallbackReceived = false;
  isEmailValidationCallbackReceived = false;
  isSecondaryEmailValidationCallbackReceived = false;
  isAddressValidationCallbackReceived = false;
  showSuccessMsgEmail = "Email";
  showSuccessMsgSecondaryEmail = "SecondaryEmail";
  showSuccessMsgPhone = "Phone";
  showSuccessMsgAddress = "Address";
  showSuccessMsgMobilePhone = "Mobile";
  showSuccessMsgFlag = false;
  showModal_Invalid = false;
  phoneModalType_Invalid = false;
  invalidDataLists = [];
  phoneNumberTypeDataLists = [];
  inValidData;
  dependentFieldsList = [];
  LABEL = {
    DATA_VALID_MESSAGE: "Contact Updated and Data Validated",
    SUCCESS: "Success",
    DATA_INVALID_VALID_MESSAGE: "Contact Updated and Data Invalid",
    WARNING: "Warning",
    NAME: "Name",
    ADDRESS_INFORMATION: "Address Information",
    SYSTEM_INFORMATION: "System Information",
    CREATED_BY: "Created By",
    LAST_MODIFIED_BY: "Last Modified By",
    CONTACT_RECORD_TYPE: "Contact Record Type",
    MAILING_ADDRESS: "Mailing Address",
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
    Verified_Valid: "Verified - Valid",
    Verified_Questionable: "Verified - Questionable",
    Unable_to_Process: "Unable to Process",
    Verified_Invalid: "Verified - Invalid",
    Verified_Ext_Invalid: "Verified - Ext Invalid",
    Read_timed_out: "Read timed out",
    Landline: "LandLine",
  };

  /* for Error and Warning custom Popup - Added on 28/7/2021  */
  @track isErrorPopup = false;
  @track errorMessages = [];
  @track warningMessages = { message: null, data: null };
  @track isViewDuplicatesModal = false;
  whichButtonWasClicked = null;

  get isPhysicianIndependenceDisabled() {
    return (
      !this.physicianIndependenceOptions ||
      !this.physicianIndependenceOptions.length
    );
  }
  //Testing
  @wire(getRecordUi, {
    recordIds: "$recordId",
    layoutTypes: "Full",
    modes: "View",
  })
  recordInfo({ data, error }) {
    if (data) {
      var jsonData = JSON.stringify(data);
      var objData = JSON.parse(jsonData);
      var recordTypeId = objData.records[this.recordId].recordTypeId;
      this.recordTypeId = recordTypeId;
      this.layoutSections =
        objData.layouts.Contact[recordTypeId].Full.View.sections;
      this.recordData = objData;
      this.contactRecordData = data.records[this.recordId].fields;
      this.updatedAddressDetails.Job_Function__c =
        this.contactRecordData.Job_Function__c != null
          ? this.contactRecordData.Job_Function__c.value
          : "";
      this.updatedAddressDetails.Physician_Independence__c =
        this.contactRecordData.Physician_Independence__c != null
          ? this.contactRecordData.Physician_Independence__c.value
          : "";
      this.objectInfoFields = Object.entries(data.objectInfos.Contact.fields);
      this.setActiveSections();
      for (var i = 0; i < this.layoutSections.length; i++) {
        var currSection = this.layoutSections[i];
        if (currSection.useHeading == true) {
          var incr = i + 1;
          while (
            this.layoutSections[incr] != null &&
            this.layoutSections[incr].useHeading == false
          ) {
            var nextRows = this.layoutSections[incr].layoutRows;
            if (nextRows != null && nextRows.length > 0) {
              currSection.layoutRows.push(...nextRows);
            }
            incr += 1;
          }
        }
      }

      console.log("**SECTIONS", this.layoutSections);
      var temp = [];
      var index = 0;
      for (var i = 0; i < this.layoutSections.length; i++) {
        if (i == 0 || this.layoutSections[i].useHeading == true) {
          temp.push(this.layoutSections[i]);
          index++;
        }
      }
      var dependentList = [];
      var dependentMap = [];
      this.objectInfoFields.forEach((r) => {
        if (r[1].controllingFields.length > 0) {
          dependentList.push(r[1].apiName);
          r[1].controllingFields.forEach((k) => {
            dependentList.push(k);
            dependentMap.push({ key: r[1].apiName, value: k });
            dependentMap.push({ key: k, value: r[1].apiName });
          });
        }
      });

      this.layoutSections.forEach((s) => {
        s.layoutRows.forEach((r) => {
          r.layoutItems.forEach((i) => {
            i.isNameField = i.label == this.LABEL.NAME;
            i.isMailingAddressField = i.label == this.LABEL.MAILING_ADDRESS;
            i.jobFunctionField = i.label == "Job Function";
            i.physicianIndependenceField = i.label == "Physician Independence";

            //Added on 25 Aug 2021 Hide Contact Origin Field on New/Edit Page Layout
            //https://salesforce.stackexchange.com/questions/123755/how-do-i-hide-field-on-edit-new-record-page-and-still-display-them-in-the-view-p
            i.isContactOriginField = i.label == "Contact Origin";
            i.isContactOwner = i.label == "Contact Owner"; //Kalyani added
            console.log("*** label changes " + i.label);
            console.log("inide");
            if (s.heading == this.LABEL.SYSTEM_INFORMATION) {
              i.isSystemInformationSection = true;
              if (i.label == this.LABEL.CREATED_BY) {
                i.isCreatedBy = true;
              } else if (i.label == this.LABEL.LAST_MODIFIED_BY) {
                i.isLastModifiedBy = true;
              } else if (i.label == this.LABEL.CONTACT_RECORD_TYPE) {
                i.isRecordType = true;
              } else if (
                i.label != this.LABEL.CREATED_BY &&
                i.label != this.LABEL.LAST_MODIFIED_BY &&
                i.label != this.LABEL.CONTACT_RECORD_TYPE &&
                i.label != ""
              ) {
                i.isOtherSystemInfoData = true;
              }
            } else if (s.heading == "Data Quality") {
              i.editableForUpdate = false;
            } else {
              i.isSystemInformationSection = false;
            }

            i.layoutComponents.forEach((p) => {
              //handle formula fields
              var apiName = p.apiName;
              this.fieldApiName = apiName;
              if (dependentList.includes(p.apiName)) {
                i.isControllingField = true;
                i.controllingFields = "";
                dependentMap.forEach((t) => {
                  if (t.key == p.apiName) {
                    i.controllingFields += t.value + ",";
                  }
                });
                i.controllingFields = i.controllingFields.slice(0, -1);
              }
              this.objectInfoFields.forEach((r) => {
                var objectInfoFieldData = r;
                objectInfoFieldData.forEach((l) => {
                  if (l.apiName != null)
                    if (l.calculated == true) {
                      i.isFormulaField = true;
                    } /*else if (i.label == 'Contact Owner') { //Kalyani commented
                                            i.isFormulaField = false;
                                        }*/
                });
              });
            });
            //Kalyani compact added- starts
            setTimeout(() => {
              // loadScript(this, densitySettings)
              var isCompactLayout =
                this.template.querySelectorAll(".slds-form-element_horizontal")
                  .length > 0;
              if (isCompactLayout) {
                var elements =
                  this.template.querySelectorAll(".slds-p-top_large");
                elements.forEach((e) => {
                  if (
                    e.classList.value.indexOf("compactview-top-padding") === -1
                  )
                    e.classList.add("compactview-top-padding");
                });
                console.log("***LOADED");
                if (i.label == this.LABEL.NAME) {
                  i.isCompactView = true;
                }
              }
            }, 2500);
            //Kalyani compact added - ends
          });
        });
      });

      this.layoutSections = temp;
      console.log("**SECTIONS", this.layoutSections);
      this.mapMarkers = [
        {
          location: {
            City: this.contactRecordData.MailingCity.value,
            Country: this.contactRecordData.MailingCountryCode.value,
            PostalCode: this.contactRecordData.MailingPostalCode.value,
            State: this.contactRecordData.MailingStateCode.value,
            Street: this.contactRecordData.MailingStreet.value,
          },
          title: "Title",
          description: "Description",
        },
      ];
      console.log("mapMarkers---" + this.mapMarkers[0].location.City);
    } else {
    }
  }

  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  contactInfo;

  setActiveSections() {
    this.layoutSections.forEach((sectionHeading) => {
      this.activeSections.push(sectionHeading.id);
    });
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: MAILING_COUNTRY_FIELD,
  })
  countryList({ error, data }) {
    if (data) {
      this.mailingCountries = [...data.values];
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: "$recordTypeId",
    fieldApiName: MAILING_STATE_FIELD,
  })
  stateList({ error, data }) {
    if (data) {
      this.allMailingStates = data;
    }
  }

  @wire(getPicklistValuesByRecordType, {
    objectApiName: CONTACT_OBJECT,
    recordTypeId: "$recordTypeId",
  })
  fetchValues({ error, data }) {
    if (!this.contactInfo) {
      console.log("inside error");
    }
    if (data && data.picklistFieldValues) {
      console.log("**data " + data);
    }
  }

  handleJobFunctionChange(event) {
    //this.contactDetail.Job_Function__c = event.target.value;
    let key =
      this.allPhysicianIndependence.controllerValues[event.target.value];
    let filteredPhysicianIndependence =
      this.allPhysicianIndependence.values.filter((opt) =>
        opt.validFor.includes(key)
      );
    this.physicianIndependenceOptions = filteredPhysicianIndependence.length
      ? [DEFAULT_PICKLIST_VALUE, ...filteredPhysicianIndependence]
      : [];
  }

  addressChanged(event) {
    this.isAddressChanged = true;
    this.updatedAddressDetails.MailingStreet =
      event.target.street == null ? "" : event.target.street;
    this.updatedAddressDetails.MailingCity =
      event.target.city == null ? "" : event.target.city;
    this.updatedAddressDetails.MailingPostalCode =
      event.target.postalCode == null ? "" : event.target.postalCode;
    this.updatedAddressDetails.MailingStateCode =
      event.target.province == null ? "" : event.target.province;
    this.updatedAddressDetails.MailingCountryCode =
      event.target.country == null ? "" : event.target.country;
    this.handleCountryChange(event.target.country);
  }

  handleCountryChange(countryName) {
    let key = this.allMailingStates.controllerValues[countryName];
    let filteredStates = this.allMailingStates.values.filter((opt) =>
      opt.validFor.includes(key)
    );
    this.mailingStates = [...filteredStates];
  }

  handleFieldChange(event) {
    //not needed
    if (event.target.name == "Email") {
      this.isEmailChanged = true;
    } else if (event.target.name == "Secondary_Email__c") {
      this.isSecondaryEmailChanged = true;
    } else if (event.target.name == "Phone") {
      this.isPhoneChanged = true;
    } else if (event.target.name == "MobilePhone") {
      this.isMobileChanged = true;
    }
  }
  @api
  callButton() {
    //not needed
    console.log("recordInfo--" + JSON.stringify(this.recordInfo));
  }

  callSaveAndNewButton() {
    this.isSaveAndNewButton = true;
    this.template.querySelector(".save-and-new-button").click();
  }

  handleSubmit(event) {
    try {
      // modified on 29/7/2021
      event.preventDefault();
      let fields = event.detail.fields;
      fields.MailingStreet = this.updatedAddressDetails.MailingStreet;
      fields.MailingCity = this.updatedAddressDetails.MailingCity;
      fields.MailingPostalCode = this.updatedAddressDetails.MailingPostalCode;
      fields.MailingStateCode = this.updatedAddressDetails.MailingStateCode;
      fields.MailingCountryCode = this.updatedAddressDetails.MailingCountryCode;
      console.log("fields", fields);

      /* Added on 28/7/2021 */
      if (this.whichButtonWasClicked == "ContinueToSave") {
        this.updateContact(fields);
      } else {
        this.updatedContactDetail = fields;
        this.validateDQServices();
      }
    } catch (error) {
      console.log("ERROR: ", error);
    }
  }

  handleSuccess() {
    if (this.inValidData != "invalidData") {
      console.log("OUTPUT_inValidData : ", this.inValidData);
      // Added on 25 Aug 2021 - Show DQ message if there was a DQ callout
      if (this.inValidData == "DQ_CALLOUT") {
        const evt = new ShowToastEvent({
          title: this.LABEL.SUCCESS,
          message: this.LABEL.DATA_VALID_MESSAGE,
          variant: this.LABEL.SUCCESS,
        });
        this.dispatchEvent(evt);
      } else {
        const showDataUpdatedEvt = new ShowToastEvent({
          title: "Success",
          message: "Contact Information Data Updated",
          variant: "success",
        });
        this.dispatchEvent(showDataUpdatedEvt);
      }
    } else if (this.inValidData == "invalidData") {
      const showInvalidDataToastMessageEvt = new ShowToastEvent({
        title: this.LABEL.WARNING,
        message: this.LABEL.DATA_INVALID_VALID_MESSAGE,
        variant: this.LABEL.WARNING,
      });
      this.dispatchEvent(showInvalidDataToastMessageEvt);
    }
    this.resetAll();
    this.updatedContactDetail = {};

    if (this.isEditModalWindow) {
      this.closeParentModal();
      if (this.isSaveAndNewButton) {
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: "Contact",
            actionName: "new",
          },
        });
      }
    } else {
      this.isEditMode = false;
    }
    this.isSpinner = false;
    this.whichButtonWasClicked = null;
  }

  closeParentModal() {
    const closeModalEvent = new CustomEvent("close");
    // Dispatches the event.
    this.dispatchEvent(closeModalEvent);
  }

  cancelEdit() {
    this.errorMessages = [];
    this.isErrorPopup = false;
    this.resetAll();
    if (this.isEditModalWindow) {
      this.closeParentModal();
    } else {
      this.isEditMode = false;
    }
  }

  editButton(event) {
    console.log("****layout section  before llll " + this.layoutSections);
    let key =
      this.allMailingStates.controllerValues[
        this.contactRecordData.MailingCountryCode.value
      ];
    let filteredStates = this.allMailingStates.values.filter((opt) =>
      opt.validFor.includes(key)
    );
    this.mailingStates = [...filteredStates];
    this.isEditMode = true;
    console.log("****layout section after llll " + this.layoutSections);
    /*var fieldName = event.target.dataset.name;
        this.layoutSections.forEach(s => {

            s.layoutRows.forEach(r => {
                r.layoutItems.forEach(i => {
                    i.layoutComponents.forEach(p => {
                        if(p.apiName == fieldName) {
                            console.log('Hi in edit field');
                            p.isEditMode = true;
                            console.log('Hi 22');
                        }else{
                            p.isEditMode = false;
                        }
                    })
                })
            })
        })*/
  }

  navigateToCreatedUserRecord() {
    var createdDateId = this.contactData.CreatedById.value;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        objectApiName: "User",
        recordId: createdDateId,
        actionName: "view",
      },
    }).then((url) => {
      window.open(url);
    });
  }
  navigateToLastModifiedUserRecord() {
    var LastModifiedById = this.contactData.LastModifiedById.value;
    this[NavigationMixin.GenerateUrl]({
      type: "standard__recordPage",
      attributes: {
        objectApiName: "User",
        recordId: LastModifiedById,
        actionName: "view",
      },
    }).then((url) => {
      window.open(url);
    });
  }

  validateDQServices() {
    try {
      this.isSpinner = true;
      this.resetAll();
      let email = this.updatedContactDetail.Email;
      let secondaryEmail = this.updatedContactDetail.Secondary_Email__c;
      let phone = this.updatedContactDetail.Phone;
      let mobilePhone = this.updatedContactDetail.MobilePhone;
      console.log("*** validate");
      getDQMetadata()
        .then((result) => {
          var DQMetetadataRecords = result;
          console.log("DQMetetadataRecords " + DQMetetadataRecords);
          DQMetetadataRecords.forEach((t) => {
            if (t.DeveloperName == "Email_Validation") {
              //validate primary email
              if (
                email != null &&
                email != "" &&
                email != this.contactRecordData.Email.value &&
                t.DQ_Service_On__c
              ) {
                this.DQValidationEmail(email, "isPrimaryEmail");
              } else {
                this.isEmailValidationCallbackReceived = true;
                if (this.isEmptyOrNull(email)) {
                  this.updatedContactDetail.Email_Verification_Status__c = null;
                  this.updatedContactDetail.Email_Verification_Date__c = null;
                }
              }

              //validate secondary email
              if (
                secondaryEmail != null &&
                secondaryEmail != "" &&
                secondaryEmail !=
                  this.contactRecordData.Secondary_Email__c.value &&
                t.DQ_Service_On__c
              ) {
                this.DQValidationEmail(secondaryEmail, "isSecondaryEmail");
              } else {
                this.isSecondaryEmailValidationCallbackReceived = true;
                if (this.isEmptyOrNull(secondaryEmail)) {
                  this.updatedContactDetail.Secondary_Email_Verification_Status__c =
                    null;
                  this.updatedContactDetail.Secondary_Email_Verification_Date__c =
                    null;
                }
              }
            } else if (t.DeveloperName == "Phone_Validation") {
              //validate phone
              if (
                phone != null &&
                phone != "" &&
                phone != this.contactRecordData.Phone.value &&
                t.DQ_Service_On__c
              ) {
                this.DQValidationPhone(phone, "isPhone");
              } else {
                if (this.isEmptyOrNull(phone)) {
                  this.updatedContactDetail.Phone_Verification_Status__c = null;
                  this.updatedContactDetail.Phone_Verification_Date__c = null;
                }
                this.isPhoneValidationCallbackReceived = true;
              }

              //validate mobile phone
              if (
                mobilePhone != null &&
                mobilePhone != "" &&
                mobilePhone != this.contactRecordData.MobilePhone.value &&
                t.DQ_Service_On__c
              ) {
                this.DQValidationPhone(mobilePhone, "isMobile");
              } else {
                this.isMobileValidationCallbackReceived = true;
                if (this.isEmptyOrNull(mobilePhone)) {
                  this.updatedContactDetail.Mobile_Phone_Verification_Status__c =
                    null;
                  this.updatedContactDetail.Mobile_Phone_Verification_Date__c =
                    null;
                }
              }
            } else if (t.DeveloperName == "Address_Validation") {
              let oldAddress =
                this.getEmptyStringForNullValue(
                  this.contactRecordData.MailingStreet.value
                ) +
                this.getEmptyStringForNullValue(
                  this.contactRecordData.MailingCity.value
                ) +
                this.getEmptyStringForNullValue(
                  this.contactRecordData.MailingCountryCode.value
                ) +
                this.getEmptyStringForNullValue(
                  this.contactRecordData.MailingStateCode.value
                ) +
                this.getEmptyStringForNullValue(
                  this.contactRecordData.MailingPostalCode.value
                );
              let newAddress =
                this.getEmptyStringForNullValue(
                  this.updatedContactDetail.MailingStreet
                ) +
                this.getEmptyStringForNullValue(
                  this.updatedContactDetail.MailingCity
                ) +
                this.getEmptyStringForNullValue(
                  this.updatedContactDetail.MailingCountryCode
                ) +
                this.getEmptyStringForNullValue(
                  this.updatedContactDetail.MailingStateCode
                ) +
                this.getEmptyStringForNullValue(
                  this.updatedContactDetail.MailingPostalCode
                );

              if (
                this.isAddressChanged &&
                oldAddress != newAddress &&
                !this.isEmptyOrNull(newAddress) &&
                !this.updatedContactDetail.Sync_Address_With_Account__c &&
                this.updatedContactDetail.AccountId !=
                  this.contactRecordData.AccountId
              ) {
                if (t.DQ_Service_On__c) {
                  this.DQValidationAddress();
                }
              } else {
                this.isAddressValidationCallbackReceived = true;
                if (this.isAddressChanged && this.isEmptyOrNull(newAddress)) {
                  this.updatedContactDetail.Address_Verification_Status__c =
                    null;
                  this.updatedContactDetail.Address_Verification_Date__c = null;
                }
              }
            }
          });
          console.log("*** validate else");
        })

        .catch((error) => {});

      //handle callback at a time of DQ api call
      let checkAllResponse = window.setInterval(() => {
        if (
          this.isMobileValidationCallbackReceived &&
          this.isPhoneValidationCallbackReceived &&
          this.isEmailValidationCallbackReceived &&
          this.isSecondaryEmailValidationCallbackReceived &&
          this.isAddressValidationCallbackReceived
        ) {
          this.isSpinner = true;
          //show Success Message - starts
          if (
            this.showSuccessMsgAddress == this.LABEL.Address &&
            this.showSuccessMsgEmail == this.LABEL.Email &&
            this.showSuccessMsgPhone == this.LABEL.Phone &&
            this.showSuccessMsgSecondaryEmail == this.LABEL.SecondaryEmail &&
            this.showSuccessMsgMobilePhone == this.LABEL.Mobile
          ) {
            this.saveData();
            this.inValidData = "DQ_CALLOUT";
            //this.isSpinner = false;
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
            this.isSpinner = false;
          } else if (
            this.showSuccessMsgAddress == "exceptionAddress" ||
            this.showSuccessMsgEmail == "exceptionEmail" ||
            this.showSuccessMsgSecondaryEmail == "exceptionSecondaryEmail" ||
            this.showSuccessMsgPhone == "exceptionPhone" ||
            this.showSuccessMsgMobilePhone == "exceptionMobilePhone"
          ) {
            //handle if DQ API has exception
            this.inValidData = "APIException";
            this.saveData();
            // this.isSpinner = false;
          }
          window.clearInterval(checkAllResponse);
        }
      }, 1000);
    } catch (error) {
      console.log("ERROR_DQ : ", error);
    }
  }

  DQValidationEmail(email, emailCheck) {
    //this.inValidData = 'DQ_CALLOUT';
    DQValidateEmail({ emailName: email, recordId: null })
      .then((result) => {
        var emailResponss = result;
        this.emailResponss = emailResponss;
        if (emailCheck == "isPrimaryEmail") {
          this.isEmailValidationCallbackReceived = true;
          //handle exception - set status and date as null when exception is received
          if (
            emailResponss.exceptionMessage == this.LABEL.Read_timed_out ||
            emailResponss.exceptionMessage != null
          ) {
            this.showSuccessMsgEmail = "exceptionEmail";
          }
          if ((this.showSuccessMsgEmail = "exceptionEmail")) {
            this.updatedContactDetail.Email_Verification_Status__c = null;
            this.updatedContactDetail.Email_Verification_Date__c = null;
          }
        }
        if (emailCheck == "isSecondaryEmail") {
          this.isSecondaryEmailValidationCallbackReceived = true;
          //handle exception - set status and date as null when exception is received
          if (
            emailResponss.exceptionMessage == this.LABEL.Read_timed_out ||
            emailResponss.exceptionMessage != null
          ) {
            this.showSuccessMsgSecondaryEmail = "exceptionSecondaryEmail";
          }

          if ((this.showSuccessMsgSecondaryEmail = "exceptionSecondaryEmail")) {
            this.updatedContactDetail.Secondary_Email_Verification_Status__c =
              null;
            this.updatedContactDetail.Secondary_Email_Verification_Date__c =
              null;
          }
        }

        if (emailResponss.statusDescription != null) {
          if (emailCheck == "isPrimaryEmail") {
            this.DQVerifyPrimaryEmail(emailResponss);
          }
          if (emailCheck == "isSecondaryEmail") {
            this.DQVerifySecondaryEmail(emailResponss);
          }
        }
        // set the callback flag for Email
      })
      .catch((error) => {
        //this.showSuccessMsgEmail = 'exceptionEmail';
      });
  }
  DQVerifyPrimaryEmail(emailResponss) {
    var today = this.calculateTodaysDate();
    this.updatedContactDetail.Email_Verification_Status__c =
      emailResponss.statusDescription;
    this.updatedContactDetail.Email_Verification_Date__c = today;

    console.log(
      "DQVerifyPrimaryEmail: ",
      this.updatedContactDetail.Email_Verification_Status__c,
      this.updatedContactDetail.Email_Verification_Date__c
    );

    if (
      emailResponss.statusDescription == this.LABEL.Verified_Valid ||
      emailResponss.statusDescription == this.LABEL.Verified_Questionable ||
      emailResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgEmail = this.LABEL.Email;
    } else if (emailResponss.statusDescription == this.LABEL.Verified_Invalid) {
      this.invalidDataLists.push("Email");
      this.showSuccessMsgEmail = this.LABEL.invalidEmail;
    }
  }
  DQVerifySecondaryEmail(emailResponss) {
    var today = this.calculateTodaysDate();
    this.updatedContactDetail.Secondary_Email_Verification_Status__c =
      emailResponss.statusDescription;
    this.updatedContactDetail.Secondary_Email_Verification_Date__c = today;
    console.log(
      "DQVerifySecondaryEmail : ",
      this.updatedContactDetail.Secondary_Email_Verification_Status__c,
      this.updatedContactDetail.Secondary_Email_Verification_Date__c
    );
    if (
      emailResponss.statusDescription == this.LABEL.Verified_Valid ||
      emailResponss.statusDescription == this.LABEL.Verified_Questionable ||
      emailResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgSecondaryEmail = this.LABEL.SecondaryEmail;
    } else if (emailResponss.statusDescription == this.LABEL.Verified_Invalid) {
      this.invalidDataLists.push("Secondary Email");
      this.showSuccessMsgSecondaryEmail = this.LABEL.invalidSecondaryEmail;
    }
  }
  DQValidationPhone(phone, phoneCheck) {
    //this.inValidData = 'DQ_CALLOUT';
    DQValidatePhone({
      phoneNumber: phone,
      recordId: this.recordId,
      fromLocation: "isEdit",
      MailingCountryCode: this.updatedContactDetail.MailingCountryCode,
    })
      .then((result) => {
        this.phoneResponss = result;
        console.log("PhoneResponss : ", result);
        var phoneResponss = this.phoneResponss;
        // set the callback flag for phone
        if (phoneCheck == "isPhone") {
          this.isPhoneValidationCallbackReceived = true;

          //handle exception - set status and date as null when exception is received
          if (
            phoneResponss.exceptionMessage == this.LABEL.Read_timed_out ||
            phoneResponss.exceptionMessage != null
          ) {
            this.showSuccessMsgPhone = "exceptionPhone";
          }

          if ((this.showSuccessMsgPhone = "exceptionPhone")) {
            this.updatedContactDetail.Phone_Verification_Status__c = null;
            this.updatedContactDetail.Phone_Verification_Date__c = null;
          }
        }
        if (phoneCheck == "isMobile") {
          this.isMobileValidationCallbackReceived = true;
          //handle exception - set status and date as null when exception is received
          if (
            phoneResponss.exceptionMessage == this.LABEL.Read_timed_out ||
            phoneResponss.exceptionMessage != null
          ) {
            this.showSuccessMsgMobilePhone = "exceptionMobilePhone";
          }
          if ((this.showSuccessMsgMobilePhone = "exceptionMobilePhone")) {
            this.updatedContactDetail.Mobile_Phone_Verification_Status__c =
              null;
            this.updatedContactDetail.Mobile_Phone_Verification_Date__c = null;
          }
        }

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

        this.isSpinner = false;
      })
      .catch((error) => {
        //this.showSuccessMsgPhone = 'exceptionPhone';
      });
  }
  DQVerifyPhone(phoneResponss) {
    var today = this.calculateTodaysDate();
    this.updatedContactDetail.Phone_Verification_Status__c =
      phoneResponss.statusDescription;
    this.updatedContactDetail.Phone_Verification_Date__c = today;
    if (
      phoneResponss.statusDescription == this.LABEL.Verified_Valid ||
      phoneResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgPhone = this.LABEL.Phone;
      //duplicate message
    }
    /*else if (phoneResponss.statusDescription == this.LABEL.Verified_Invalid || phoneResponss.statusDescription == this.LABEL.Verified_Ext_Invalid) {}*/
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
  }

  DQVerifyMobilePhone(phoneResponss) {
    var today = this.calculateTodaysDate();
    this.updatedContactDetail.Mobile_Phone_Verification_Status__c =
      phoneResponss.statusDescription;
    this.updatedContactDetail.Mobile_Phone_Verification_Date__c = today;
    if (
      phoneResponss.statusDescription == this.LABEL.Verified_Valid ||
      phoneResponss.statusDescription == this.LABEL.Unable_to_Process
    ) {
      this.showSuccessMsgMobilePhone = this.LABEL.Mobile;
    }
    /*else if (phoneResponss.statusDescription == this.LABEL.Verified_Invalid || phoneResponss.statusDescription == this.LABEL.Verified_Ext_Invalid) {}*/
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
  }
  DQValidationAddress() {
    //this.inValidData = 'DQ_CALLOUT';
    let addressLine1, addressLine2, addressLine3, addressLine4, mailingStreet;

    //Updated on 12/8/2021 - fixed address edit issue
    if (
      this.updatedContactDetail.MailingStreet &&
      this.updatedContactDetail.MailingStreet != ""
    ) {
      mailingStreet = this.updatedContactDetail.MailingStreet.split("\n");
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

    DQValidateAddress({
      address1: addressLine1 == null ? "" : addressLine1,
      address2: addressLine2 == null ? "" : addressLine1,
      address3: addressLine3 == null ? "" : addressLine1,
      address4: addressLine4 == null ? "" : addressLine1,
      cityName:
        this.updatedContactDetail.MailingCity == undefined
          ? ""
          : this.updatedContactDetail.MailingCity,
      stateName:
        this.updatedContactDetail.MailingStateCode == undefined
          ? ""
          : this.updatedContactDetail.MailingStateCode,
      zipCode:
        this.updatedContactDetail.MailingPostalCode == undefined
          ? ""
          : this.updatedContactDetail.MailingPostalCode,
      countryName:
        this.updatedContactDetail.MailingCountryCode == undefined
          ? ""
          : this.updatedContactDetail.MailingCountryCode,
      timeOut: null,
    }).then((result) => {
      if (result.status.includes("Error")) {
        this.showSuccessMsgAddress = "exceptionAddress";
        this.updatedContactDetail.Address_Verification_Status__c = null;
        this.updatedContactDetail.Address_Verification_Date__c = null;
      } else {
        var today = this.calculateTodaysDate();
        this.updatedContactDetail.Address_Verification_Status__c =
          result.status;
        this.updatedContactDetail.Address_Verification_Date__c = today;
        if (result.status == "valid" || result.status == "questionable") {
          this.showSuccessMsgAddress = this.LABEL.Address;
        } else if (result.status == "invalid") {
          this.invalidDataLists.push("MailingAddress");
          this.showSuccessMsgAddress = this.LABEL.invalidAddress;
        }
      }
      this.isAddressValidationCallbackReceived = true;
    });
  }
  calculateTodaysDate() {
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth() + 1;
    var yyyy = today.getFullYear();
    today = yyyy + "-" + mm + "-" + dd;
    return today;
  }

  saveData() {
    this.isSpinner = true;
    this.updatedContactDetail.OwnerId = "ownerid"; //;
    console.log(
      "Save_Data : ",
      JSON.parse(JSON.stringify(this.updatedContactDetail))
    );
    this.template
      .querySelector("lightning-record-edit-form")
      .submit(this.updatedContactDetail);
  }

  handleNo() {
    this.saveData();
    this.showModal_Invalid = false;
    this.phoneModalType_Invalid = false;
    this.inValidData = "invalidData";
    this.isSpinner = true;
  }
  handleYes() {
    this.resetAll();
    this.showModal_Invalid = false;
    this.phoneModalType_Invalid = false;
  }
  resetAll() {
    this.invalidDataLists = [];
    this.phoneNumberTypeDataLists = [];
    this.showSuccessMsgFlag = false;
    this.isEmailValidationCallbackReceived = false;
    this.isMobileValidationCallbackReceived = false;
    this.isSecondaryEmailValidationCallbackReceived = false;
    this.isPhoneValidationCallbackReceived = false;
    this.isAddressValidationCallbackReceived = false;
    this.showModal_Invalid = false;
    this.phoneModalType_Invalid = false;
    this.showSuccessMsgEmail = "Email";
    this.showSuccessMsgSecondaryEmail = "SecondaryEmail";
    this.showSuccessMsgPhone = "Phone";
    this.showSuccessMsgAddress = "Address";
    this.showSuccessMsgMobilePhone = "Mobile";
    this.inValidData = "";
  }

  /** Added on 28 July 2021
   *   This method updates the contact record by skipping the duplicate check rule
   *   when the user clicks on the "Continue Save" button.
   */
  updateContact(data) {
    this.isSpinner = true;
    this.isErrorPopup = false;

    let duplicateContact = JSON.parse(JSON.stringify(data));
    duplicateContact.Id = this.recordId;
    console.log("duplicateContact : ", duplicateContact);

    /* fill the verification status and date of the DQ system */
    duplicateContact["Email_Verification_Status__c"] =
      this.updatedContactDetail.hasOwnProperty("Email_Verification_Status__c")
        ? this.updatedContactDetail.Email_Verification_Status__c
        : duplicateContact.Email_Verification_Status__c;
    duplicateContact["Email_Verification_Date__c"] =
      this.updatedContactDetail.hasOwnProperty("Email_Verification_Date__c") &&
      this.updatedContactDetail.Email_Verification_Date__c
        ? this.formatDate(this.updatedContactDetail.Email_Verification_Date__c)
        : duplicateContact.Email_Verification_Date__c;
    duplicateContact["Secondary_Email_Verification_Status__c"] =
      this.updatedContactDetail.hasOwnProperty(
        "Secondary_Email_Verification_Status__c"
      )
        ? this.updatedContactDetail.Secondary_Email_Verification_Status__c
        : duplicateContact.Secondary_Email_Verification_Status__c;
    duplicateContact["Secondary_Email_Verification_Date__c"] =
      this.updatedContactDetail.hasOwnProperty(
        "Secondary_Email_Verification_Date__c"
      ) && this.updatedContactDetail.Secondary_Email_Verification_Date__c
        ? this.formatDate(
            this.updatedContactDetail.Secondary_Email_Verification_Date__c
          )
        : duplicateContact.Secondary_Email_Verification_Date__c;
    duplicateContact["Phone_Verification_Status__c"] =
      this.updatedContactDetail.hasOwnProperty("Phone_Verification_Status__c")
        ? this.updatedContactDetail.Phone_Verification_Status__c
        : duplicateContact.Phone_Verification_Status__c;
    duplicateContact["Phone_Verification_Date__c"] =
      this.updatedContactDetail.hasOwnProperty("Phone_Verification_Date__c") &&
      this.updatedContactDetail.Phone_Verification_Date__c
        ? this.formatDate(this.updatedContactDetail.Phone_Verification_Date__c)
        : duplicateContact.Phone_Verification_Date__c;
    duplicateContact["Mobile_Phone_Verification_Status__c"] =
      this.updatedContactDetail.hasOwnProperty(
        "Mobile_Phone_Verification_Status__c"
      )
        ? this.updatedContactDetail.Mobile_Phone_Verification_Status__c
        : duplicateContact.Mobile_Phone_Verification_Status__c;
    duplicateContact["Mobile_Phone_Verification_Date__c"] =
      this.updatedContactDetail.hasOwnProperty(
        "Mobile_Phone_Verification_Date__c"
      ) && this.updatedContactDetail.Mobile_Phone_Verification_Date__c
        ? this.formatDate(
            this.updatedContactDetail.Mobile_Phone_Verification_Date__c
          )
        : duplicateContact.Mobile_Phone_Verification_Date__c;
    duplicateContact["Address_Verification_Status__c"] =
      this.updatedContactDetail.hasOwnProperty("Address_Verification_Status__c")
        ? this.updatedContactDetail.Address_Verification_Status__c
        : duplicateContact.Address_Verification_Status__c;
    duplicateContact["Address_Verification_Date__c"] =
      this.updatedContactDetail.hasOwnProperty(
        "Address_Verification_Date__c"
      ) && this.updatedContactDetail.Address_Verification_Date__c
        ? this.formatDate(
            this.updatedContactDetail.Address_Verification_Date__c
          )
        : duplicateContact.Address_Verification_Date__c;

    console.log(
      "duplicateContact2 : ",
      JSON.parse(JSON.stringify(duplicateContact))
    );

    updateDuplicateContact({ duplicateContact })
      .then((result) => {
        console.log("Result", result);
        this.isSpinner = false;
        if (result.isSuccuss) {
          //show success message only if data is valid
          if (this.inValidData != "invalidData") {
            // Added on 25 Aug 2021 - Show DQ message if there was a DQ callout
            if (this.inValidData == "DQ_CALLOUT") {
              const evt = new ShowToastEvent({
                title: this.LABEL.SUCCESS,
                message: this.LABEL.DATA_VALID_MESSAGE,
                variant: this.LABEL.SUCCESS,
              });
              this.dispatchEvent(evt);
            } else {
              const showDataUpdatedEvt = new ShowToastEvent({
                title: "Success",
                message: "Contact Information Data Updated",
                variant: "success",
              });
              this.dispatchEvent(showDataUpdatedEvt);
            }
          } else if (this.inValidData == "invalidData") {
            const showInvalidDataToastMessageEvt = new ShowToastEvent({
              title: this.LABEL.WARNING,
              message: this.LABEL.DATA_INVALID_VALID_MESSAGE,
              variant: this.LABEL.WARNING,
            });
            this.dispatchEvent(showInvalidDataToastMessageEvt);
          }
          window.setTimeout(() => {
            window.location.reload();
          }, 1500);
        } else {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error",
              message: result.message,
              variant: "error",
            })
          );
        }
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }

  handleError(event) {
    this.isSpinner = false;
    this.showModal_Invalid = false;

    console.log("Error: ", JSON.parse(JSON.stringify(event.detail)));

    let formErrorDetails = JSON.parse(JSON.stringify(event.detail));
    this.isErrorPopup = true;
    this.whichButtonWasClicked = null;
    let errors = [];
    let warnings = { message: null, data: null };
    if (formErrorDetails.hasOwnProperty("output")) {
      if (formErrorDetails.output.hasOwnProperty("fieldErrors")) {
        Object.entries(formErrorDetails.output.fieldErrors).forEach(
          ([key, value]) => {
            value.forEach((obj) => {
              errors.push(`${obj.fieldLabel}: ${obj.message}`);
            });
          }
        );
      }
      if (
        formErrorDetails.output.hasOwnProperty("errors") &&
        formErrorDetails.output.errors.length
      ) {
        formErrorDetails.output.errors.forEach((fielderror) => {
          if (fielderror.errorCode === "DUPLICATES_DETECTED") {
            warnings.data = fielderror.duplicateRecordError.matchResults;
          }
        });
      }
    }

    if (warnings.data != null) {
      warnings.message = formErrorDetails.detail;
      this.warningMessages = warnings;
    } else {
      errors = [formErrorDetails.detail, ...errors];
      this.errorMessages = errors;
    }
    console.log("warning : ", this.warningMessages);
    console.log("error : ", this.errorMessages);
  }

  handleContinueToSave() {
    this.whichButtonWasClicked = "ContinueToSave";
    this.template.querySelector(".continue-save-button").click();
  }

  handleViewDuplicatesModal() {
    this.isViewDuplicatesModal = !this.isViewDuplicatesModal;
  }

  handleVisibilityOfErrorPopup() {
    this.isErrorPopup = !this.isErrorPopup;
  }

  handleViewRecordDatail(event) {
    this.navigateToRecordViewPage(event.currentTarget.dataset.id);
  }

  navigateToRecordViewPage(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId,
        objectApiName: "Contact",
        actionName: "view",
      },
    });
  }

  get checkVisibilityOfErrorIcon() {
    return this.errorMessages.length > 0;
  }
  get checkVisibilityOfWarningIcon() {
    return this.warningMessages.message != null;
  }

  get popoverHeaderStyle() {
    return (
      (this.errorMessages.length
        ? "slds-popover slds-popover_error slds-nubbin_bottom-left"
        : "slds-popover slds-popover_warning  slds-nubbin_bottom-left") +
      " popover-custom-width"
    );
  }
  editRecordType() {
    alert("record type edited");
  }

  /* Added on 29/07/2021 */

  handleOnSubmit(whichButtonClicked) {
    if (whichButtonClicked == "Save") {
      this.whichButtonWasClicked = "Save";
      this.template.querySelector(".save-button").click();
    }
  }

  validateFields(event) {
    this.isErrorPopup = false;
    this.errorMessages = [];
    this.warningMessages = { message: null, data: null };
    let errors = [];

    try {
      let allInputsAreFilled = true;
      [...this.template.querySelectorAll("lightning-input-field")].forEach(
        (element) => {
          element.reportValidity();
          // Added on 17 Aug, 2020 -->  !element.reportValidity()
          if (
            (element.required &&
              (element.value == null || element.value == "")) ||
            !element.reportValidity()
          ) {
            if (
              this.contactInfo &&
              this.contactInfo.data &&
              this.contactInfo.data.fields.hasOwnProperty(element.fieldName) &&
              this.contactInfo.data.fields[
                element.fieldName
              ].dataType.toLowerCase() != "boolean"
            ) {
              allInputsAreFilled = false;
              let fieldLabel =
                this.contactInfo.data.fields[element.fieldName].label;
              errors.push(fieldLabel);
            }
          }
        }
      );
      if (allInputsAreFilled) {
        console.log("All form entries look valid. Ready to submit!");

        this.isSpinner = true;
        this.errorMessages = [];

        this.handleOnSubmit(event.target.name);
      } else {
        console.log("Please update the invalid form entries and try again.");
        console.log("errors : ", errors);
        this.errorMessages = errors;
        this.isErrorPopup = true;
      }
    } catch (error) {
      console.log("OUTPUT : ", error);
    }
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

  isEmptyOrNull(value) {
    return value == null || value == "";
  }

  getEmptyStringForNullValue(value) {
    return value == null ? "" : value;
  }

  //Kalyani added for compact view - starts
  renderedCallback() {
    /* setTimeout(() => {
            // loadScript(this, densitySettings)  
            var isCompactLayout = this.template.querySelectorAll('.slds-form-element_horizontal').length > 0;
            if(isCompactLayout){
                var elements = this.template.querySelectorAll('.slds-p-top_large');
                elements.forEach(e => {
                    if(e.classList.value.indexOf('compactview-top-padding') === -1)
                        e.classList.add('compactview-top-padding');
                }); 
            console.log('***LOADED');           
        }
        }, 1000);        
        console.log('***LOADING...');  */
  }

  //Kalyani added for compact view - ends
}
