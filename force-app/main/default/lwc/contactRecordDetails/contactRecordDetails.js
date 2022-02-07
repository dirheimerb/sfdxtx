import { LightningElement, api, wire, track } from "lwc";

import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecordUi, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import MAILING_COUNTRY_FIELD from "@salesforce/schema/Contact.MailingCountryCode";
import MAILING_STATE_FIELD from "@salesforce/schema/Contact.MailingStateCode";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
const DEFAULT_PICKLIST_VALUE = { label: "--None--", value: "none" };

import updateDuplicateContact from "@salesforce/apex/C360DMContactCreateController.updateDuplicateContact";
import EmailBouncedDate from "@salesforce/schema/Contact.EmailBouncedDate";

/*//SFSC - 6173 Detailed description of values used on Contact record details form

DQ_CALLOUT - This is used to check if we get valid data from DQ and to display success toast message (Toast message - Contact Updated and Data Validated)
invalidData - This is used to check if we get invalid data from DQ and to display warning toast message  (Toast message - Contact Updated and Data Invalid)

********User stories for DQ API status value***********
https://wlgore.atlassian.net/browse/CPINS-7 - DQ Services: Real-Time Address Validation
https://wlgore.atlassian.net/browse/CPINS-6 - DQ Services: Real-Time Email 
https://wlgore.atlassian.net/browse/CPINS-8 - DQ Services: Real-Time Phone Validation
*/

export default class ContactRecordDetails extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api isEditModalWindow = false;
  @api isEditMode = false;
  isViewMode = true;
  isSaveAndNewButton = false; // This variable use for If the user clicks on the "Save & New" button then update the record and open a new contact page otherwise refresh the current page.
  @track layoutSections = [];
  activeSections = [];
  headingSections = [];
  isViewAllDependentModal = false;
  jobFunctionOptions = [DEFAULT_PICKLIST_VALUE];
  physicianIndependenceOptions = [];
  recordTypeId;
  fieldApiName;
  isAddressChanged = false;
  mapMarkers;
  allMailingStates;
  @track sectionLabel = "Show";
  @track buttonVisible = false;
  @track isNameLabel = false;
  @track isSpinner = false; // Added on 28/7/2021
  recordData;
  updatedContactDetail = {};
  updatedAddressDetails = {};

  contextOfPageReference = null;

  mailingCountries = [];
  mailingStates = [];
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
    Read_timed_out: "Read timed out",
    Landline: "LandLine",
  };

  /* for Error and Warning custom Popup - Added on 28/7/2021  */
  @track isErrorPopup = false;
  @track errorMessages = [];
  @track warningMessages = { message: null, data: null };
  @track isViewDuplicatesModal = false;
  whichButtonWasClicked = null;
  @track showDQMOdal = false; //for DQ popup -SFSC - 6173
  @track dqFieldsToValidate = []; //This list is used to push values as Email, Secondary email etc and pass that list into dq validation component
  isUpdatedDQSystemRelatedFields = false; //SFSC - 6173 Added on 18 Jan 2022 - This is being used to track any changes in the fields related to the DQ system

  get isPhysicianIndependenceDisabled() {
    return (
      !this.physicianIndependenceOptions ||
      !this.physicianIndependenceOptions.length
    );
  }

  // Added on 2 Feb 2022 - For Get a reference to the current page in Salesforce - SFSC - 7070
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    let state = currentPageReference.state; // state holds any query params
    this.contextOfPageReference = state.inContextOfRef;
  }

  //Testing
  @wire(getRecordUi, {
    recordIds: "$recordId",
    layoutTypes: "Full",
    modes: "View",
  })
  recordInfo({ data }) {
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
                      p.isFormulaField = true;
                    } else if (i.label == "Contact Owner") {
                      i.isFormulaField = false;
                    }
                });
              });
            });
            //Kalyani compact added- starts
            setTimeout(() => {
              var isCompactLayout =
                this.template.querySelectorAll(".slds-form-element_horizontal")
                  .length > 0;
              if (isCompactLayout) {
                this.updateCompactViewCSS();
                console.log("***LOADED");
                if (i.label == this.LABEL.NAME) {
                  i.isCompactView = true;
                }
                if (i.label == this.LABEL.MAILING_ADDRESS) {
                  i.isCompactView = true;

                  console.log("in mailing");
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

  updateCompactViewCSS() {
    var elements = this.template.querySelectorAll(".slds-p-top_large");
    elements.forEach((e) => {
      if (e.classList.value.indexOf("compactview-top-padding") === -1)
        e.classList.add("compactview-top-padding");
    });
    const style = document.createElement("style");
    style.innerText = ".slds-map {min-width: 0px !important;}";
    this.template.querySelector("lightning-map").appendChild(style);
  }

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

  handleJobFunctionChange(event) {
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

  callSaveAndNewButton() {
    this.isSpinner = true; //SFSC - 7070
    this.isSaveAndNewButton = true;
    this.template.querySelector(".save-and-new-button").click();
  }

  handleSubmit(event) {
    this.isUpdatedDQSystemRelatedFields = false; // SFSC - 6173 Added on 18 Jan 2022
    try {
      // modified on 29/7/2021
      event.preventDefault();
      let fields = event.detail.fields;
      if (this.isAddressChanged) {
        fields.MailingStreet = this.updatedAddressDetails.MailingStreet;
        fields.MailingCity = this.updatedAddressDetails.MailingCity;
        fields.MailingPostalCode = this.updatedAddressDetails.MailingPostalCode;
        fields.MailingStateCode = this.updatedAddressDetails.MailingStateCode;
        fields.MailingCountryCode =
          this.updatedAddressDetails.MailingCountryCode;
      } else {
        fields.MailingStreet = this.contactRecordData.MailingStreet.value;
        fields.MailingCity = this.contactRecordData.MailingCity.value;
        fields.MailingPostalCode =
          this.contactRecordData.MailingPostalCode.value;
        fields.MailingStateCode = this.contactRecordData.MailingStateCode.value;
        fields.MailingCountryCode =
          this.contactRecordData.MailingCountryCode.value;
      }

      console.log("fields", fields);

      /* Added on 28/7/2021 */
      if (this.whichButtonWasClicked == "ContinueToSave") {
        this.updateAddress(); // SFSC-6173: 20-01 added to update address for duplicate record
        this.updateContact(this.updatedContactDetail); //SFSC - 6173 - changed "fields" to "this.updateContactDetail" - 19-01
      } else {
        //SFSC - 6173 - DQ Code Optimization starts
        this.updatedContactDetail = fields;
        this.updateAddress(); //SFSC-6173: 20-01 To add address details in updatedContactDetail
        this.showDQMOdal = true;

        let email = this.updatedContactDetail.Email;
        let secondaryEmail = this.updatedContactDetail.Secondary_Email__c;
        let phone = this.updatedContactDetail.Phone;
        let mobilePhone = this.updatedContactDetail.MobilePhone;
        this.dqFieldsToValidate = [];
        if (
          email != null &&
          email != "" &&
          this.contactRecordData.Email.value != email
        ) {
          this.dqFieldsToValidate.push("Email");
          this.isUpdatedDQSystemRelatedFields = true; // SFC - 6173 Added on 18 Jan 2022
        }

        if (
          secondaryEmail != null &&
          secondaryEmail != "" &&
          secondaryEmail != this.contactRecordData.Secondary_Email__c.value
        ) {
          this.dqFieldsToValidate.push("SecondaryEmail");
          this.isUpdatedDQSystemRelatedFields = true; // SFSC - 6173 Added on 18 Jan 2022
        }

        if (
          phone != null &&
          phone != "" &&
          phone != this.contactRecordData.Phone.value
        ) {
          this.dqFieldsToValidate.push("Phone");
          this.isUpdatedDQSystemRelatedFields = true; // SFSC - 6173 Added on 18 Jan 2022
        }

        if (
          mobilePhone != null &&
          mobilePhone != "" &&
          mobilePhone != this.contactRecordData.MobilePhone.value
        ) {
          this.dqFieldsToValidate.push("MobilePhone");
          this.isUpdatedDQSystemRelatedFields = true; // SFSC - 6173 Added on 18 Jan 2022
        }

        if (this.isAddressValidationRequired()) {
          this.dqFieldsToValidate.push("Address");
          this.isUpdatedDQSystemRelatedFields = true; //SFSC - 6173 -  Added on 18 Jan 2022
        }

        var modalLoading = setInterval(() => {
          console.log("1");
          var modal = this.template.querySelector("c-d-q-validation");
          if (modal != null) {
            clearInterval(modalLoading);
            modal.validateDQServices();
          }
        }, 100);
        //SFSC - 6173 - DQ Code Optimization ends
      }
    } catch (error) {
      console.log("ERROR: ", error);
    }
  }

  isAddressValidationRequired() {
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
      this.getEmptyStringForNullValue(this.updatedContactDetail.MailingStreet) +
      this.getEmptyStringForNullValue(this.updatedContactDetail.MailingCity) +
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
      oldAddress != newAddress &&
      !this.isEmptyOrNull(newAddress) &&
      !this.updatedContactDetail.Sync_Address_With_Account__c &&
      this.updatedContactDetail.AccountId != this.contactRecordData.AccountId
    ) {
      return true;
    }
    return false;
  }

  handleSuccess() {
    if (this.inValidData != "invalidData") {
      console.log("OUTPUT_inValidData : ", this.inValidData);
      // Added on 25 Aug 2021 - Show DQ message if there was a DQ callout
      if (!this.isUpdatedDQSystemRelatedFields) {
        // SFSC - 6173 Added on 18 Jan 2022
        const evt = new ShowToastEvent({
          title: this.LABEL.SUCCESS,
          message: "Contact has been updated successfully.",
          variant: this.LABEL.SUCCESS,
        });
        this.dispatchEvent(evt);
      } else if (this.inValidData == "DQ_CALLOUT") {
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

    /*SFSC - 7070 - 01-02-2020  " - 
    When user clicks on "Save and new" and clicks on "cancel" of contact create form, 
    user should navigate back to contact record detials page*/
    if (this.isEditModalWindow) {
      this.closeParentModal();
      if (this.isSaveAndNewButton) {
        this[NavigationMixin.Navigate]({
          type: "standard__objectPage",
          attributes: {
            objectApiName: "Contact",
            actionName: "new",
          },
          state: {
            inContextOfRef: this.contextOfPageReference, // Added on 2 Feb 2022   - SFSC - 7070
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
    setTimeout(() => {
      var isCompactLayout =
        this.template.querySelectorAll(".slds-form-element_horizontal").length >
        0;
      if (isCompactLayout) {
        this.updateCompactViewCSS();
      }
    }, 2500);
  }

  editButton() {
    let key =
      this.allMailingStates.controllerValues[
        this.contactRecordData.MailingCountryCode.value
      ];
    let filteredStates = this.allMailingStates.values.filter((opt) =>
      opt.validFor.includes(key)
    );
    this.mailingStates = [...filteredStates];
    this.isEditMode = true;
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
    console.log(
      "Save_Data : ",
      JSON.parse(JSON.stringify(this.updatedContactDetail))
    );
    this.template
      .querySelector("lightning-record-edit-form")
      .submit(this.updatedContactDetail);
  }

  resetAll() {
    this.inValidData = "";
    this.dqFieldsToValidate = [];
  }

  /** Added on 28 July 2021
   *   This method updates the contact record by skipping the duplicate check rule
   *   when the user clicks on the "Continue Save" button.
   */
  updateContact(data) {
    this.isSpinner = true;
    this.isErrorPopup = false;

    let duplicateContact = data; //SFSC- 6173 - 19-01

    duplicateContact.Id = this.recordId;

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

          /* Added on 28 Jan 2022 -SFSC-7070 - if the user clicked on the "Save And New" button 
                            then update record and open new contact page therwise refresh the  current page*/
          if (this.isSaveAndNewButton) {
            this[NavigationMixin.Navigate]({
              type: "standard__objectPage",
              attributes: {
                objectApiName: "Contact",
                actionName: "new",
              },
              state: {
                inContextOfRef: this.contextOfPageReference, // Added on 2 Feb 2022   - SFSC - 7070
              },
            });
          } else {
            window.setTimeout(() => {
              // https://stackoverflow.com/questions/22753052/remove-url-parameters-without-refreshing-page
              /*SFSC-7070 - Added on 28 Jan 2022 - - Added after clicking on save , it should navigate to contact record details page 
                                      Removed edit URL and updated contact record view URL without redirecting to another page*/
              window.history.pushState(
                {},
                document.title,
                `/lightning/r/Contact/${this.recordId}/view`
              );
              window.location.reload();
            }, 1500);
          }
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
      year = "" + d.getFullYear();

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

  //SFSC - 6173 DQ Code Optimization starts
  dqValidationCompleted(event) {
    this.updatedContactDetail = event.detail;
    this.inValidData = event.detail.inValidData;
    this.saveData();
    console.log("****** event in parent contact details " + event.detail);
  }

  closeDQPopupModal(event) {
    this.showDQMOdal = event.detail;
    this.isSpinner = false;
    console.log("****** event in parent flag details " + event.detail);
  }
  //Added on 20-01 to map the address fields to updatedContactDetail
  updateAddress() {
    if (this.isAddressChanged) {
      this.updatedContactDetail.MailingStreet =
        this.updatedAddressDetails.MailingStreet;
      this.updatedContactDetail.MailingCity =
        this.updatedAddressDetails.MailingCity;
      this.updatedContactDetail.MailingPostalCode =
        this.updatedAddressDetails.MailingPostalCode;
      this.updatedContactDetail.MailingStateCode =
        this.updatedAddressDetails.MailingStateCode;
      this.updatedContactDetail.MailingCountryCode =
        this.updatedAddressDetails.MailingCountryCode;
      this.isUpdatedDQSystemRelatedFields = true; // SFSC - 6173-  Added on 18 Jan 2022
    } else {
      this.updatedContactDetail.MailingStreet =
        this.contactRecordData.MailingStreet.value;
      this.updatedContactDetail.MailingCity =
        this.contactRecordData.MailingCity.value;
      this.updatedContactDetail.MailingPostalCode =
        this.contactRecordData.MailingPostalCode.value;
      this.updatedContactDetail.MailingStateCode =
        this.contactRecordData.MailingStateCode.value;
      this.updatedContactDetail.MailingCountryCode =
        this.contactRecordData.MailingCountryCode.value;
    }
  }
  //SFSC - 6173 DQ Code Optimization ends

  //SFSC-7116 31-01-2022 Added key press event to prevent record submission on "Enter" key press
  handleKeyPress(component) {
    if (component.which == 13) {
      component.preventDefault();
    }
  }
}
