import { LightningElement, wire, api, track } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { updateRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
//import CONTACT_OBJECT from '@salesforce/schema/Contact';

// import contactWrapper from '@salesforce/apex/Customer360SearchModels.ContactWrapper';

export default class ContactRecordSelectionPage extends NavigationMixin(
  LightningElement
) {
  @api showRecordTypeModal = false;
  @api showRecordTypeWithoutModal = false;
  @track showContactCreateModal = false;
  @api showNewContactCard = "";
  @api showAutofillContactCard = false;
  @api isGlobalSearchPage; // Checking which page the user on

  recordTypeIdValue = "";
  currentContactContext;
  @api selectedRecordTypeId = "";
  @track selectedRecordTypeName = "";
  @api contactRecordTypeValues = [];

  //@api forceUpdate = false;
  @api contactData;
  //@track objectInfo;
  @track recordId; //SFSC - 7070 - get the record id of page
  inContextOfReference = null; //Added on 02 Feb 2022 - SFSC - 7070 - This variable stores the URL where the form is opened.
  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  contactObjectInfo;

  //Added on 27 Sep, 2021
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    console.log("!!!Inside pageReference");
    let state = currentPageReference.state; // state holds any query params
    if (state != null) {
      //State is used to know where the user is, so the correct modals opens
      //SFSC - 7070 changes

      if (state.c__globalSearch) {
        this.isGlobalSearchPage = state.c__globalSearch;
      }

      this.inContextOfReference = state.inContextOfRef;
      let base64Context = state.inContextOfRef;

      console.log("base64Context1 : ", base64Context);
      if (base64Context != null && base64Context.startsWith("1.")) {
        base64Context = base64Context.substring(2);
        let addressableContext = JSON.parse(window.atob(base64Context));
        console.log("addressableContext : ", addressableContext);
        if (
          currentPageReference != null &&
          currentPageReference.state != null
        ) {
          this.currentContactContext = addressableContext;
        }
      }
    }
  }

  @api forUpdate() {
    this.recordTypes();
  }

  get recordTypes() {
    if (
      this.contactRecordTypeValues == null ||
      this.contactRecordTypeValues.length == 0
    ) {
      this.initContactRecordTypes();
    }
    this.handleContactModalNext();
    return this.contactRecordTypeValues;
  }

  initContactRecordTypes() {
    //get contact record type values
    var recordtypeinfo = this.contactObjectInfo.data.recordTypeInfos;

    var recordTypeDict = Object.values(recordtypeinfo);
    var sorted = [];
    var prevSelection = false;
    if (
      this.contactData.selectedRecordTypeName != undefined &&
      this.contactData.selectedRecordTypeId != undefined
    ) {
      prevSelection = true;
    }

    recordTypeDict
      .filter(
        (t) =>
          t.defaultRecordTypeMapping == true &&
          t.name != "Master" &&
          t.available == true
      )
      .forEach((t) => sorted.push(t));
    recordTypeDict
      .filter(
        (t) =>
          t.defaultRecordTypeMapping == false &&
          t.name != "Master" &&
          t.available == true
      )
      .forEach((t) => sorted.push(t));

    this.contactRecordTypeValues = [];
    for (var i = 0; i < sorted.length; i++) {
      var record = sorted[i];
      this.contactRecordTypeValues.push({
        label: record.name,
        value: record.name,
        recordTypeIdValue: record.name + "-" + record.recordTypeId,
        defaultRecordType:
          prevSelection &&
          record.name == this.contactData.selectedRecordTypeName
            ? true
            : record.defaultRecordTypeMapping,
      });
    }

    if (!prevSelection) {
      console.log("inside prev selection");
      this.contactRecordTypeValues.forEach((t) => {
        if (t.defaultRecordType == true) {
          var splitted = t.recordTypeIdValue.split("-");
          this.selectedRecordTypeName = splitted[0];
          this.selectedRecordTypeId = splitted[1];
        }
      });
    } else {
      this.selectedRecordTypeId = this.contactData.selectedRecordTypeId;
      this.selectedRecordTypeName = this.contactData.selectedRecordTypeName;
    }
  }

  handleRecordType(evt) {
    this.recordTypeIdValue = evt.target.dataset.recordtypeidvalue;
    if (this.recordTypeIdValue != null && this.recordTypeIdValue != undefined) {
      this.recordTypeIdValue = this.recordTypeIdValue.split("-");
      this.selectedRecordTypeName = this.recordTypeIdValue[0];
      this.selectedRecordTypeId = this.recordTypeIdValue[1];
    }
  }

  handleRecordTypeModalNext(event) {
    //pass all record type details
    var recordTypeDetails = {
      contactCreateModal: true,
      recordTypeName: this.selectedRecordTypeName,
      recordTypeId: this.selectedRecordTypeId,
      contactRecordTypeValues: this.contactRecordTypeValues,
    };
    this.raiseEvent("recordtypemodalnext", recordTypeDetails);
  }

  handleContactModalNext() {
    var recordTypeDetails = {
      contactRecordTypeValues: this.contactRecordTypeValues,
    };
    this.raiseEvent("contactmodalnext", recordTypeDetails);
  }

  raiseEvent(name, args) {
    const customEvent = new CustomEvent(name, {
      detail: args,
    });

    this.dispatchEvent(customEvent);
  }

  closeModal() {
    // Added on 2 Feb 2022 - Navigate to Go Back  - SFSC - 7070 - starts
    if (this.isGlobalSearchPage === "true") {
      // SFSC - 7070 - 06 Feb
      this.raiseEvent("closerecordtypemodal", this.contactData); //SFSC - 7070 - added to contact modal
      this[NavigationMixin.Navigate]({
        type: "standard__navItemPage",
        attributes: {
          apiName: "Global_Profile_Search",
        },
      });
    } else if (this.inContextOfReference) {
      let base64Context = this.inContextOfReference;
      if (base64Context && base64Context.startsWith("1.")) {
        base64Context = base64Context.substring(2);
      }
      let addressableContext = base64Context
        ? JSON.parse(window.atob(base64Context))
        : null;
      console.log("AddressableContext : ", addressableContext);
      if (addressableContext) {
        this[NavigationMixin.Navigate](addressableContext);
      }
    }
    // Added on 2 Feb 2022 - Navigate to Go Back  - SFSC - 7070 - ends
  }
}
