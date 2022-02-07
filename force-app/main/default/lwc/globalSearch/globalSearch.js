import { LightningElement, track, api, wire } from "lwc";
import searchGlobalData from "@salesforce/apex/GlobalSearchBeforeCreateController.searchGlobalData";
import { NavigationMixin } from "lightning/navigation";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import TickerSymbol from "@salesforce/schema/Account.TickerSymbol";

export default class GlobalSearch extends NavigationMixin(LightningElement) {
  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  contactObjectInfo;

  @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
  leadObjectInfo;

  bShowModal = false;
  isSearchButton = true; //to disable search button
  @track searchKey = "";
  searchPrefix = "";
  globalProfiles = [];
  @track globalProfileCurrentPage = [];
  displayGlobalProfileTable = false;

  startingRecord = 1; //start record position per page
  endingRecord = 0; //end record position per page
  pageSize = 5; //default value we are assigning
  totalRecountCount = 0; //total record count received from all retrieved records
  totalPage = 0; //total number of page is needed to display all records
  page = 1;
  showSpinner = false;
  isResult = false;
  isTimeOut = false;
  showRecordTypeModal = false;
  showContactCreateModal = false;
  contactRecordTypeValues = [];
  @api isSearchFromLead = false;
  @api isSearchFromContact = false;
  hasMultipleRecordTypeAccess = true;
  @track selectedleadRecordTypeId = "";
  @track showLeadRecordTypeModal = false;
  //isRendered = false; //SFSC - 7070

  // model for holding contact creation data
  @track contactData = {
    FirstName: null,
    LastName: null,
    GlobalPartyId: null,
    Physician_Registration_No__c: null,
    Phone: null,
    MobilePhone: null,
    Extension__c: null,
    Email: null,
    MailingStreet: null,
    OtherStreet: null,
    MailingCity: null,
    MailingPostalCode: null,
    MailingCountry: null,
    MailingState: null,
  };

  resetAll() {
    this.globalProfiles = [];
    this.globalProfileCurrentPage = [];
    this.startingRecord = 1;
    this.endingRecord = 0;
    this.pageSize = 5;
    this.totalRecountCount = 0;
    this.totalPage = 0;
    this.page = 1;
    this.displayGlobalProfileTable = false;
  }

  renderedCallback() {
    //SFSC - 7070 - changed from "connectedCallBack" to "rendered callback"

    //SFSC - 7070 - - added to stop calling further method again and again starts
    if (this.isRendered) return;
    this.globalProfiles = [];
    this.globalProfileCurrentPage = [];
    this.searchKey = "";
    this.displayGlobalProfileTable = false;
    window.setTimeout(
      (self) => {
        // Changed on 2 Feb 2022 - SFSC - 7070
        self.checkForMultipleRecordTypeAccess();
      },
      1500,
      this
    );
  }

  checkForMultipleRecordTypeAccess() {
    let recordtypeinfo; //=  ((this.contactObjectInfo &&  this.contactObjectInfo.hasOwnProperty('data') && this.contactObjectInfo.data) ? this.contactObjectInfo.data.recordTypeInfos : null);

    if (this.isSearchFromContact == "true") {
      recordtypeinfo =
        this.contactObjectInfo &&
        this.contactObjectInfo.hasOwnProperty("data") &&
        this.contactObjectInfo.data
          ? this.contactObjectInfo.data.recordTypeInfos
          : null;
    } else if (this.isSearchFromLead == "true") {
      recordtypeinfo =
        this.leadObjectInfo &&
        this.leadObjectInfo.hasOwnProperty("data") &&
        this.leadObjectInfo.data
          ? this.leadObjectInfo.data.recordTypeInfos
          : null;
    }

    if (recordtypeinfo) {
      let recordTypeDict = Object.values(recordtypeinfo);
      let sorted = [];

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

      sorted.forEach((t) => {
        if (
          t.defaultRecordTypeMapping == true &&
          this.isSearchFromContact == "true"
        ) {
          this.contactData.selectedRecordTypeId = t.recordTypeId;
        } else if (this.isSearchFromLead == "true") {
          console.log("inside lead");
          this.selectedleadRecordTypeId = t.recordTypeId;
        }
      });
      this.hasMultipleRecordTypeAccess = sorted.length > 1;
    }
    //added as a part of replacement of global search
    if (this.hasMultipleRecordTypeAccess) {
      this.showRecordTypeModal = true;
      this.showContactCreateModal = false;
    } else {
      this.showRecordTypeModal = false;
      this.showContactCreateModal = true;
    }
    this.isRendered = true; //SFSC - 7070 - set isRendered flag as true
  }

  getSearchValue(event) {
    this.searchKey = event.target.value;
    this.isResult = false;
    this.isTimeOut = false;
    var searchRegex = /[@0-9]+/;

    if (this.searchKey.length == 0 || !this.searchKey.match(searchRegex)) {
      this.globalProfiles = [];
      this.displayGlobalProfileTable = false;
      this.isResult = false;
      this.isTimeOut = false;
      this.isSearchButton = true;
    } else {
      this.isSearchButton = false;
    }
  }

  searchGlobalProfileData() {
    //reset timeout and reset flag
    this.isResult = false;
    this.isTimeOut = false;
    this.globalProfileCurrentPage = [];
    this.displayGlobalProfileTable = false;

    this.showSpinner = true;
    searchGlobalData({ searchExpression: this.searchKey })
      .then((result) => {
        var globalProfileData = result.globalProfileData;
        var exceptionMessage = result.exceptionMessage;

        //Code for Pagination
        if (globalProfileData != null && globalProfileData.length > 0) {
          this.totalRecountCount = globalProfileData.length;
        }
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        if (
          globalProfileData != null &&
          globalProfileData.length > 0 &&
          this.searchKey.length != 0
        ) {
          this.globalProfiles = globalProfileData;
          this.displayGlobalProfileTable = true;
          this.isResult = false;
        } else {
          this.globalProfiles = [];
          this.displayGlobalProfileTable = false;
          this.isResult = true;
        }
        if (exceptionMessage == "Read timed out") {
          this.isTimeOut = true;
          this.isResult = false;
        }

        //append global profile data value
        this.globalProfileDataValue(this.globalProfiles);

        // logic for Pagination
        this.displayRecordPerPage(this.page);
        this.showSpinner = false;
      })
      .catch((error) => {
        console.log("Exception");
      });
  }

  globalProfileDataValue() {
    for (var i = 0; i < this.globalProfiles.length; i++) {
      var currGlobalProfile = this.globalProfiles[i];
      currGlobalProfile.dataSources = this.splitAndNewLine(
        currGlobalProfile?.dataSources,
        "~~"
      );
      var addresses = currGlobalProfile.fullAddress;
      for (var j = 0; j < addresses?.length; j++) {
        var currAddress = addresses[j];
        currAddress.concatenatedAddress = this.getFullAddress(
          currAddress.addressLine1,
          currAddress.addressLine2,
          currAddress.addressLine3,
          currAddress.addressLine4,
          currAddress.cityName,
          currAddress.stateProvinceCode,
          currAddress.postalCode,
          currAddress.countryName
        );
        if (currAddress.concatenatedAddress == "null.  ") {
          currAddress.concatenatedAddress = "";
        }
      }
    }
  }

  getFullAddress(
    addressLine1,
    addressLine2,
    addressLine3,
    addressLine4,
    cityName,
    stateProvinceCode,
    stateProvinceName,
    postalCode,
    countryName
  ) {
    // system.debug('City name -> ' + cityName);
    var fullAddress = "";
    fullAddress =
      (addressLine1 != null ? addressLine1 + ". " : "") +
      (addressLine2 != null ? addressLine2 + ". " : "") +
      (cityName != null ? cityName + ", " : "") +
      (stateProvinceCode != null ? stateProvinceCode + " " : "") +
      (stateProvinceName != null ? stateProvinceName + " " : "") +
      (postalCode != null ? postalCode + " " : "") +
      (countryName != null ? countryName : " ");
    //system.debug('full address name -> ' + fullAddress);
    console.log("full address name -> " + fullAddress);
    return fullAddress;
  }

  splitAndNewLine(val, seperator) {
    if (val) return val.split(seperator);
    else return "";
  }

  //clicking on previous button this method will be called
  previousHandler() {
    if (this.page > 1) {
      this.page = this.page - 1; //decrease page by 1
      this.displayRecordPerPage(this.page);
    }
  }

  //clicking on next button this method will be called
  nextHandler() {
    if (this.page < this.totalPage && this.page !== this.totalPage) {
      this.page = this.page + 1; //increase page by 1
      this.displayRecordPerPage(this.page);
    }
  }

  displayRecordPerPage(page) {
    this.startingRecord = (page - 1) * this.pageSize;
    this.endingRecord = this.pageSize * page;

    this.endingRecord =
      this.endingRecord > this.totalRecountCount
        ? this.totalRecountCount
        : this.endingRecord;

    this.globalProfileCurrentPage = this.globalProfiles.slice(
      this.startingRecord,
      this.endingRecord
    );

    //logic to disable and enable previous and next button
    this.prevNextButtonHandling(page);
  }

  ////Method to disable and enable previous and next button
  prevNextButtonHandling(page) {
    this.isFirstPage = this.page == 1;
    this.isLastPage = this.page == this.totalPage || this.totalPage == 0;
  }

  navigateContactCreation(event) {
    var globalprofileindex = event.target.dataset.globalprofileindex;
    globalprofileindex =
      parseInt(this.pageSize * (this.page - 1)) + parseInt(globalprofileindex); // // 11

    var phoneNumbersData = this.globalProfiles[globalprofileindex].phoneNumbers;
    var fullAddress = this.globalProfiles[globalprofileindex].fullAddress;
    var emailAddress =
      this.globalProfiles[globalprofileindex].contactPointEmails;
    var partyIdentifications =
      this.globalProfiles[globalprofileindex].partyIdentifications;

    //Autofill latest phone numbers
    var latestHomePhoneNumber = "",
      latestMobilePhoneNumber = "",
      latestExtensionNumber = "";
    for (var i = 0; i < phoneNumbersData.length; i++) {
      if (phoneNumbersData[i].contactType.toLowerCase() == "home") {
        latestHomePhoneNumber = phoneNumbersData[i].telephoneNumber;
        latestExtensionNumber = phoneNumbersData[i].extensionNumber;
        break;
      }
    }

    for (var i = 0; i < phoneNumbersData.length; i++) {
      if (phoneNumbersData[i].contactType.toLowerCase() == "mobile") {
        latestMobilePhoneNumber = phoneNumbersData[i].telephoneNumber;
        break;
      }
    }

    if (latestHomePhoneNumber.length > 0) {
      latestHomePhoneNumber = this.trimTrailingChar(latestHomePhoneNumber);
    }
    if (latestMobilePhoneNumber.length > 0) {
      latestMobilePhoneNumber = this.trimTrailingChar(latestMobilePhoneNumber);
    }

    //Autofill latest Address
    var currentMailingStreet,
      currentMailingStateName,
      currentMailingStateCode,
      currentOtherStreet,
      currentMailingCity,
      currentPostalCode,
      currentMailingCountry;
    for (var i = 0; i < fullAddress.length; i++) {
      var currAddress = fullAddress[i];
      currentMailingStreet = currAddress.addressLine1;
      currentOtherStreet = currAddress.addressLine2;
      currentMailingCity = currAddress.cityName;
      currentPostalCode = currAddress.postalCode;
      //currentMailingStateCode = currAddress.stateProvinceCode;
      currentMailingStateName = currAddress.stateProvinceName;
      currentMailingCountry = currAddress.countryName;
      break;
    }

    //Autofill latest email address
    var emailAddressName;
    for (var i = 0; i < emailAddress.length; i++) {
      var currEmailAddress = emailAddress[i];
      emailAddressName = currEmailAddress.emailAddressName;
      break;
    }
    var partyIdentificationNumber;
    for (var i = 0; i < partyIdentifications.length; i++) {
      var currPartyIdentification = partyIdentifications[i];
      partyIdentificationNumber = currPartyIdentification.identificationNumber;
      break;
    }

    //contact creation wrapper - starts
    this.contactData.GlobalPartyId =
      this.globalProfiles[globalprofileindex].globalPartyId;
    this.contactData.FirstName =
      this.globalProfiles[globalprofileindex].firstName;
    this.contactData.LastName =
      this.globalProfiles[globalprofileindex].lastName;
    this.contactData.Phone = latestHomePhoneNumber;
    this.contactData.Extension__c = latestExtensionNumber;
    this.contactData.MobilePhone = latestMobilePhoneNumber;
    this.contactData.Physician_Registration_No__c = partyIdentificationNumber;
    this.contactData.Email = emailAddressName;
    this.contactData.MailingStreet = currentMailingStreet;
    this.contactData.OtherStreet = currentOtherStreet;
    this.contactData.MailingCity = currentMailingCity;
    this.contactData.MailingPostalCode = currentPostalCode;
    this.contactData.MailingCountry = currentMailingCountry;
    this.contactData.MailingState = currentMailingStateName;
    //contact creation wrapper - ends

    //after clicking adopt new button of global search
    if (this.hasMultipleRecordTypeAccess) {
      this.showContactCreateModal = false;
      this.showRecordTypeModal = true;
    } else {
      this.showRecordTypeModal = false;
      this.showContactCreateModal = true;
    }
  }

  navigateToRecordCreationPage() {
    if (this.isSearchFromContact == "true") {
      this.navigateNewContactCreation();
    } else if (this.isSearchFromLead == "true") {
      this.navigateToLeadCreation();
    }
  }

  navigateNewContactCreation() {
    var recordTypeId = this.contactData.selectedRecordTypeId;
    this.contactData = {}; //reset all contact data
    this.contactData.selectedRecordTypeId = recordTypeId;
    //after clicking next button of global search
    if (this.hasMultipleRecordTypeAccess) {
      this.showContactCreateModal = false;
      this.showRecordTypeModal = true;
    } else {
      this.showRecordTypeModal = false;
      this.showContactCreateModal = true;
    }
  }
  navigateToLeadCreation() {
    this.showLeadRecordTypeModal = true;
    console.log("*** selected record type id " + this.selectedLeadRecordTypeId);
    if (this.hasMultipleRecordTypeAccess) {
      //this.showContactCreateModal = false;
      console.log("inisde lead record type modal");
      this.showLeadRecordTypeModal = true;
    } else {
      this.showLeadRecordTypeModal = false;
      this[NavigationMixin.Navigate]({
        type: "standard__objectPage",
        attributes: {
          objectApiName: "Lead",
          actionName: "new",
        },
        state: {
          nooverride: "1",
          recordTypeId: this.selectedLeadRecordTypeId,
          //useRecordTypeCheck: "1",
        },
      });
    }
  }
  navigateToRecord(event) {
    var recordid = event.target.dataset.recordid;
    var datasourceindex = event.target.dataset.datasourceindex;
    var datasourceObjectNames =
      this.globalProfiles[datasourceindex].datasourceObjectNames;

    if (
      datasourceObjectNames.length > 0 &&
      datasourceObjectNames.includes("Contact")
    ) {
      //for(var i=0;i<dataSourceRecordIds.length ;i++){
      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          objectApiName: "Contact",
          recordId: recordid,
          actionName: "view",
        },
      }).then((url) => {
        window.open(url);
      });
      // }
    } else if (
      datasourceObjectNames.length > 0 &&
      datasourceObjectNames.includes("Lead")
    ) {
      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          objectApiName: "Lead",
          recordId: recordid,
          actionName: "view",
        },
      }).then((url) => {
        window.open(url);
      });
    }
  }

  trimTrailingChar(val) {
    if (val) return val.substring(0, val.length - 1);
    else return "";
  }
  /* javaScipt functions end */

  enterKeyCheck(event) {
    var searchRegex = /[@0-9]+/;
    if (event.keyCode == 13 && this.searchKey.match(searchRegex)) {
      this.searchGlobalProfileData();
    } else {
      return false;
    }
  }

  closeModal() {
    //to pass record type name to global search component and also close record type modal
    if (this.isSearchFromContact == "true") {
      this.raiseEvent("closecontactglobalsearchmodal", "");
    } else if (this.isSearchFromLead == "true") {
      this.raiseEvent("closeleadglobalsearchmodal", "");
    }
  }

  handleRecordTypeNext(event) {
    var eventData = event.detail;

    this.contactData.contactCreateModal = eventData.contactCreateModal;
    this.contactData.selectedRecordTypeId = eventData.recordTypeId;
    this.contactData.selectedRecordTypeName = eventData.recordTypeName;
    this.contactData.contactRecordTypeValues =
      eventData.contactRecordTypeValues;

    // show create contact step

    if (this.isSearchFromContact == "true") {
      this.showRecordTypeModal = false;
      this.showContactCreateModal = true;
    } else if (this.isSearchFromLead == "true") {
      this.showLeadRecordTypeModal = true;
      this.showContactCreateModal = false;
    }
  }

  closeRecordTypeModal(event) {
    var eventData = event.detail;

    this.contactData.contactCreateModal = eventData.contactCreateModal;
    this.contactData.selectedRecordTypeId = eventData.recordTypeId;
    this.contactData.selectedRecordTypeName = eventData.recordTypeName;
    this.contactData.contactRecordTypeValues =
      eventData.contactRecordTypeValues;

    this.showRecordTypeModal = false;
    this.showLeadRecordTypeModal = false;
  }

  handleContactModalNext(event) {
    var eventData = event.detail;
    this.contactData.contactRecordTypeValues =
      eventData.contactRecordTypeValues;
  }
  //checks user reocord types.
  closeContactCreateModal(event) {
    this.showContactCreateModal = false;

    // get contact data from eventArgs
    var contactEventData = event.detail;
    this.contactData = event.detail;

    this.showRecordTypeModal = false; //SFSC - 7070 - 01-02-7070 - Added when user click on cancel button of contact create page, record type page should not open
    this.isRendered = true; //SFSC - 7070 - set flag is Rendered as true
    //window.history.go(-1);//SFSC - 7070
    //eval("$A.get('e.force:refreshView').fire();") //SFSC - 7070
    //SFSC - 7070 - commenting starts - 01-02-2020 - removed when user click on cancel button of contact create page, record type page should not open
    /*if (this.hasMultipleRecordTypeAccess) {
        this.showRecordTypeModal = true;
    }*/
    //SFSC - 7070 - commenting ends - 01-02-2020
  }
  raiseEvent(name, args) {
    const customEvent = new CustomEvent(name, {
      detail: args,
    });

    this.dispatchEvent(customEvent);
  }

  // Added on 2 Feb 2022 - SFSC - 7070 - starts
  handleManualRendered() {
    this.isRendered = false;
    eval("$A.get('e.force:refreshView').fire();");
  }
  // Added on 2 Feb 2022 - SFSC - 7070 - ends
}
