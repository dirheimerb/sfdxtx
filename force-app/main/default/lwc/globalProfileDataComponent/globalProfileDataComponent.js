import { LightningElement, track, api, wire } from "lwc";
import getGlobalFileData from "@salesforce/apex/GlobalProfileData.getGlobalProfile";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class GlobalProfileDataComponent extends NavigationMixin(
  LightningElement
) {
  //SALESCLOUD_NAME = System.Label.Sales_cloud_org_name;

  searchKey;
  isSearchButton = true; //to disable search button
  globalProfiles = [];
  changedData = [];
  globalProfilesData = [];
  displayGlobalProfileTable = false;
  globalProfileCurrentPage = [];
  redirectURL = "";

  startingRecord = 1; //start record position per page
  endingRecord = 0; //end record position per page
  pageSize = 5; //default value we are assigning
  totalRecountCount = 0; //total record count received from all retrieved records
  totalPage = 0; //total number of page is needed to display all records
  page = 1;
  showSpinner = false;
  isResult = false;
  isTimeOut = false;
  isFirstPage = true;
  isLastPage = true;
  showRecordTypeModal = false;
  showContactCreateModal = false;
  hasMultipleRecordTypeAccess = true;
  //SFSC-4996 Variable declaration starts
  showObjectSelectionModal = false;
  selectedObject;
  globalprofileindex;
  isCreateButtonAvailableToUser = true;
  contactCreateAccess = false;
  leadCreateAccess = false;
  //SFSC-4996 Variable declaration ends
  isRendered = false;

  // model for holding contact creation data
  @api contactData = {
    firstName: null,
    lastName: null,
    globalPartyId: null,
    partyIdentificationNumber: null,
    phone: null,
    mobilePhone: null,
    extension: null,
    email: null,
    mailingStreet: null,
    otherStreet: null,
    mailingCity: null,
    mailingPostalCode: null,
    mailingCountry: null,
    mailingState: null,
  };

  handleSearchExpressionChange(event) {
    this.searchKey = event.target.value;
    this.isResult = false;
    this.isTimeOut = false;
    if (this.searchKey.length == 0) {
      this.globalProfiles = [];
      this.displayGlobalProfileTable = false;
      this.isResult = false;
      this.isTimeOut = false;
      this.isSearchButton = true;
    } else {
      this.isSearchButton = false;
    }
  }

  @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
  contactObjectInfo;

  @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
  leadObjectInfo; //SFSC-4996 To check for lead create access

  //SFSC 7070 changes starts
  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    let state = currentPageReference.state; // state holds any query params
    if (state != null) {
      //State is used to know where the user is, so the correct modals opens
      //SFSC - 7070 changes
      //this.isGlobalSearchPage = state.c__globalSearch;
      //this.isRendered = state.c__globalSearch;
    }
  }
  renderedCallback() {
    //SFSC - 7070 - changed from "connectedCallBack" to "rendered callback"

    //SFSC - 7070 - - added to stop calling further method again and again starts
    if (this.isRendered) return;
    window.setTimeout(
      (self) => {
        // Changed on 2 Feb 2022 - SFSC - 7070
        self.checkForMultipleRecordTypeAccess();
      },
      2500,
      this
    );
  }

  /*connectedCallBack() { 
        //SFSC - 7070 - - added to stop calling further method again and again starts       
        window.setTimeout((self) => { // Changed on 2 Feb 2022 - SFSC - 7070
            self.checkForMultipleRecordTypeAccess();
          }, 2500, this);
    }*/
  //SFSC 7070 changes ends
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

  handleSearch() {
    // show spinner
    this.showSpinner = true;

    //reset no result flag
    this.isResult = false;
    this.isTimeOut = false;
    this.globalProfileCurrentPage = [];
    this.displayGlobalProfileTable = false;

    this.resetAll();

    this.searchKey = this.searchKey.trim(" ");
    getGlobalFileData({ searchExpression: this.searchKey })
      .then((result) => {
        var allData = result.allData;
        var exceptionMessage = result.exceptionMessage;

        //Code for Pagination
        if (allData != null && allData.length > 0) {
          this.totalRecountCount = allData.length;
        }
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        if (
          allData != null &&
          allData.length > 0 &&
          this.searchKey.length != 0
        ) {
          this.globalProfiles = allData;
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

        //Start: SFSC-4996 Check if Create New button should be visible to user or not
        //Updated on 01-31-2022 for undefined check
        if (this.contactObjectInfo.data !== undefined) {
          this.contactCreateAccess = JSON.parse(
            JSON.stringify(this.contactObjectInfo)
          ).data.createable;
        }
        if (this.leadObjectInfo.data !== undefined) {
          this.leadCreateAccess = JSON.parse(
            JSON.stringify(this.leadObjectInfo)
          ).data.createable;
        }

        if (!this.contactCreateAccess && !this.leadCreateAccess) {
          this.isCreateButtonAvailableToUser = false;
        }
        //End: SFSC-4996
      })
      .catch((error) => {
        // reset contacts var with null
        this.globalProfiles = null;
        this.showSpinner = false;
        this.isResult = true;
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
      (cityName != null ? cityName + ", " : ":") +
      (stateProvinceCode != null ? stateProvinceCode + " " : "") +
      (stateProvinceName != null ? stateProvinceName + " " : "") +
      (postalCode != null ? postalCode + " " : "") +
      (countryName != null ? countryName : " ");
    //system.debug('full address name -> ' + fullAddress);
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
  //SFSC - 6953 - commented as it was added as part of SFSC - 3416 - Starts
  /*
    trimTrailingChar(val) {        
        if (val) return val.substring(0, val.length - 1);
        else return '';
    }*/
  //SFSC - 6953 - commented as it was added as part of SFSC - 3416 - ends

  ////Method to disable and enable previous and next button
  prevNextButtonHandling(page) {
    this.isFirstPage = this.page == 1;
    this.isLastPage = this.page == this.totalPage || this.totalPage == 0;
  }
  navigateContactCreation(event) {
    if (this.globalprofileindex !== undefined) {
      //SFSC - 7070 - added null check
      this.mapSelectedGlobalRecordToContactData();
    }

    /*this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: 'Contact',
				actionName: 'new'
			}, state: { // Added on 2 Feb 2022 - SFSC - 7070
				c__globalSearch: 'true',                
			}
		});  */
    //after clicking create new button of global search
    if (this.hasMultipleRecordTypeAccess) {
      this.showContactCreateModal = false;
      this.showRecordTypeModal = true;
    } else {
      this.showRecordTypeModal = false;
      this.showContactCreateModal = true;
    }
  }

  //Created this method to make the code generic for lead and contact for autofilling the record values (SFSC-4996)
  mapSelectedGlobalRecordToContactData() {
    var globalprofileindex = this.globalprofileindex;
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
        latestHomePhoneNumber = phoneNumbersData[i].telephoneNumber.trim(); //SFSC - 6953 - Added to trim white space - 24/01/2022
        latestExtensionNumber = phoneNumbersData[i].extensionNumber;
        break;
      }
    }

    for (var i = 0; i < phoneNumbersData.length; i++) {
      if (phoneNumbersData[i].contactType.toLowerCase() == "mobile") {
        latestMobilePhoneNumber = phoneNumbersData[i].telephoneNumber.trim(); //SFSC - 6953 - Added to trim white space - 24/01/2022
        break;
      }
    }

    //SFSC - 6953 - commented as it was added as part of SFSC - 3416 - Starts
    /*if(latestHomePhoneNumber.length > 0) {            
            latestHomePhoneNumber = this.trimTrailingChar(
                latestHomePhoneNumber
            );            
        }
        if (latestMobilePhoneNumber.length > 0) {            
            latestMobilePhoneNumber = this.trimTrailingChar(
                latestMobilePhoneNumber
            );            
        }*/
    //SFSC - 6953 - commented as it was added as part of SFSC - 3416 - Ends

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
    var emailAddressName;
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
  } //SFSC-4996 Method ends

  /*navigateNewContact() {
        if (this.hasMultipleRecordTypeAccess) {
            this.showContactCreateModal = false;
            this.showRecordTypeModal = true;
        } else {
            this.showRecordTypeModal = false;
            this.showContactCreateModal = true;
        }
        
    }*/
  closeRecordTypeModal(event) {
    var detailVal = event.detail;
    this.showRecordTypeModal = false;
    //Start: SFSC-4996 check if object selection window is visible to user or not
    if (this.leadCreateAccess && this.contactCreateAccess) {
      this.showObjectSelectionModal = true;
    }
    this.isRendered = false; //SFSC 7070 added
    //End: SFSC-4996
  }

  enterKeyCheck(event) {
    if (event.keyCode == 13) {
      this.handleSearch();
    } else {
      return false;
    }
    console.log("inside key check");
  }
  handleRecordTypeNext(event) {
    var eventData = event.detail;
    this.contactData.contactCreateModal = eventData.contactCreateModal;
    this.contactData.selectedRecordTypeId = eventData.recordTypeId;
    this.contactData.selectedRecordTypeName = eventData.recordTypeName;
    this.contactData.contactRecordTypeValues =
      eventData.contactRecordTypeValues;
    // show create contact step
    this.showRecordTypeModal = false;
    this.showContactCreateModal = true;
  }

  closeContactCreateModal(event) {
    this.showContactCreateModal = false;
    // get contact data from eventArgs
    var contactEventData = event.detail;
    this.contactData = event.detail;
    /*if (this.hasMultipleRecordTypeAccess) {
            this.showRecordTypeModal = true;
        } else {
            //Start:SFSC-4996
            if (this.contactCreateAccess && this.leadCreateAccess) {
                this.showObjectSelectionModal = true;
            }
            //End: SFSC-4996
        }*/
    //SFSC - 7070  - starts
    this.showRecordTypeModal = false; // 01-02-7070 - Added when user click on cancel button of contact create page, record type page should not open
    this.isRendered = true; //set flag is Rendered as true
    console.log("**** leadcreate access " + this.leadCreateAccess);
    console.log("**** contactcreate access " + this.contactCreateAccess);
    //SFSC - 7070  - ends
    //Start:SFSC-4996
    if (this.contactCreateAccess && this.leadCreateAccess) {
      this.showObjectSelectionModal = true;
    }
    //End: SFSC-4996
  }

  checkForMultipleRecordTypeAccess() {
    let recordtypeinfo =
      this.contactObjectInfo &&
      this.contactObjectInfo.hasOwnProperty("data") &&
      this.contactObjectInfo.data
        ? this.contactObjectInfo.data.recordTypeInfos
        : null;

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
        if (t.defaultRecordTypeMapping == true) {
          this.contactData.selectedRecordTypeId = t.recordTypeId;
        }
      });
      this.hasMultipleRecordTypeAccess = sorted.length > 1;
    }

    this.isRendered = true; //SFSC - 7070 - set isRendered flag as true
  }

  //SFSC-4996 Code starts
  handleCancel() {
    this.showObjectSelectionModal = false;
    this.selectedObject = null;
  }
  openObjectSelectionModal(event) {
    this.globalprofileindex = event.target.dataset.globalprofileindex;
    if (this.contactCreateAccess && this.leadCreateAccess) {
      this.showObjectSelectionModal = true;
    } else if (this.contactCreateAccess) {
      this.navigateContactCreation();
    } else if (this.leadCreateAccess) {
      this.navigateToLeadCreation();
    }
  }
  get options() {
    return [
      {
        label: "Contact",
        value: "Contact",
        defaultRecordType: this.selectedObject == "Contact",
      },
      {
        label: "Lead",
        value: "Lead",
        defaultRecordType: this.selectedObject == "Lead",
      },
    ];
  }

  handleObjectSelection(evt) {
    this.selectedObject = evt.target.dataset.selectedobject;
  }

  navigateFromObjectModal() {
    if (this.selectedObject == "Contact") {
      this.showObjectSelectionModal = false;
      this.navigateContactCreation();
    } else if (this.selectedObject == "Lead") {
      this.navigateToLeadCreation();
    }
  }

  /*get prevObjectSelection() {
        return this.selectedObject;
    }*/

  navigateToLeadCreation() {
    if (this.globalprofileindex !== undefined) {
      //SFSC - 7070 - added null check
      this.mapSelectedGlobalRecordToContactData();
    }
    const defaultValues = encodeDefaultFieldValues({
      FirstName: this.contactData.FirstName,
      LastName: this.contactData.LastName,
      Email: this.contactData.Email,
      Phone: this.contactData.Phone,
      MobilePhone: this.contactData.MobilePhone,
      Street: this.contactData.MailingStreet,
      City: this.contactData.MailingCity,
      PostalCode: this.contactData.MailingPostalCode,
      Country: this.contactData.MailingCountry,
      State: this.contactData.MailingState,
      Extension__c: this.contactData.Extension__c,
      Physician_Registration_Number__c:
        this.contactData.Physician_Registration_No__c,
      GlobalPartyId: this.contactData.GlobalPartyId,
    });

    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Lead",
        actionName: "new",
      },
      state: {
        nooverride: "1",
        useRecordTypeCheck: "1",
        defaultFieldValues: defaultValues,
      },
    });
  }

  get isObjectNextButtonDisabled() {
    return this.selectedObject == null || this.selectedObject == "";
  }
  //SFSC-4996 code ends
  // Added on 2 Feb 2022 - SFSC - 7070 - starts
  handleManualRendered() {
    this.isRendered = false;
    eval("$A.get('e.force:refreshView').fire();");
  }
  // Added on 2 Feb 2022 - SFSC - 7070 - ends
}
