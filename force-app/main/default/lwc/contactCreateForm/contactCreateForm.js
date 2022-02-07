import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { decodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import CONTACT_OBJECT from '@salesforce/schema/Contact';
import SYNCADDRESS_FIELD from '@salesforce/schema/Contact.Sync_Address_With_Account__c';
import MAILING_COUNTRY_CODE_FIELD from '@salesforce/schema/Contact.MailingCountryCode';
import MAILING_STATE_CODE_FIELD from '@salesforce/schema/Contact.MailingStateCode';
import insertDuplicateContact from '@salesforce/apex/C360DMContactCreateController.insertDuplicateContact';
import getAccountDetails from '@salesforce/apex/C360DMContactCreateController.getAccountDetails';

/*//SFSC - 6173  Detailed description of values used on Contact create form

DQ_CALLOUT - This is used to check if we get valid data from DQ and to display success toast message (Toast message - Contact Created and Data Validated)
invalidData - This is used to check if we get invalid data from DQ and to display warning toast message  (Toast message - Contact Created and Data Invalid)
APIException - This is used to check if we get any API Exception

********User stories for DQ API status value***********
https://wlgore.atlassian.net/browse/CPINS-7 - DQ Services: Real-Time Address Validation
https://wlgore.atlassian.net/browse/CPINS-6 - DQ Services: Real-Time Email 
https://wlgore.atlassian.net/browse/CPINS-8 - DQ Services: Real-Time Phone Validation
*/
const DEFAULT_PICKLIST_VALUE = { label: '--None--', value: 'none' };

export default class ContactCreateForm extends NavigationMixin(
	LightningElement
) {
	//@api recordId; //SFSC - 7070
	@api recordTypeId;  //Master record type set by default if no record is specified
	@api contactData;
	@api showContactCreateModal = false;
	@api showContactCreateWithoutModal = false;
	@api hasMultipleRecordTypeAccess = false;
	syncAddress = SYNCADDRESS_FIELD;
	@api syncAddress = false;
	contactDetail = {};
	updatedAddressDetails = {};
	isInvalidListEmpty = false;
	@track mailingCountries = [];
	@track mailingStates = [];

	@track mailingCountriesOne = [];
	@track mailingStatesOne = [];

	@track jobFunctionOptions = [DEFAULT_PICKLIST_VALUE];
	@track physicianIndependenceOptions = [];

	@api addressSelectionType = '';
	selectedAddressSelectionType = '';

	@track isErrorPopup = false;
	@track errorMessages = [];
	@track warningMessages = { message: null, data: null };

	@track isViewDuplicatesModal = false;
	@track isViewAllDependentModal = false;

	objectApiName = 'Contact';
	selectedAccountId = '';
	accountBillingAddress = null;
	allMailingStates = [];
	allMailingStatesOne = [];
	allPhysicianIndependence = [];
	whichButtonWasClicked = null;
	_WhichButtonWasLastClicked = null; // Added on 18 Jan 2022 - SFSC - 6173 
	dependentFieldName = null;

	@track isSpinner = false;
	@track toggleAddressFieldSection = false;
	contactInformationFields = {};
	currentPR;
	@api isCallFromAccount = false;
	@api parentAccountId = '';
	@api contactRecordId;
	@track accountData;
	hasLoaded = false;
	@track showDQMOdal = false; //for DQ popup - SFSC - 6173
	@track dqFieldsToValidate = [];

	// ---- VARIABLE DECLARATION FOR PAGE LAYOUT ASSIGNMENT --- START -----//

	layoutSections = [];
	activeSections = [];
	headingSections = [];
	mapMarkers;
	// ---- VARIABLE DECLARATION FOR PAGE LAYOUT ASSIGNMENT --- END
	@track contactRecordId; //SFSC - 7070     
	@api isGlobalSearchPage; //SFSC - 7070

	inContextOfReference = null; //Added on 02 Feb 2022 - SFSC - 7070 - This variable stores the URL where the form is opened.

	isComingFrom360SearchPage = false; //Added on 04 Feb 2022

	LABEL = {
		Read_timed_out: 'Read timed out',
		Email: 'Email',
		SecondaryEmail: 'SecondaryEmail',
		Phone: 'Phone',
		Mobile: 'Mobile',
		Address: 'Address',
		ADDRESS_INFORMATION: 'Address Information',
		MAILING_ADDRESS: 'Mailing Address',
		SYSTEM_INFORMATION: 'System Information',
		CREATED_BY: 'Created By',
		LAST_MODIFIED_BY: 'Last Modified By',
		CONTACT_RECORD_TYPE: 'Contact Record Type',
		NAME: 'Name',
		Landline: 'LandLine'
	};

	/* Added on 10 Aug 2021 -  To show the spinner at landing time for the first time */
	connectedCallback() {
		if (this.recordTypeId == null) this.recordTypeId = '$recordTypeId'; //Master record type set by default if no record is specified                012000000000000AAA
		this.isSpinner = true;
		let self = this;
		window.setTimeout(
			(self) => {
				self.isSpinner = false;
			},
			2500,
			this
		);
	}

	@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
	contactInfo;

	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPR = currentPageReference;
		var state = currentPageReference.state; // state holds any query params
		console.log('state : ', state);
		var base64Context = state.inContextOfRef;
		this.inContextOfReference = state.inContextOfRef; // Added on 2 Feb 2022 - SFSC - 7070
		this.isComingFrom360SearchPage = (state.c__globalSearch != null); // Added on 4 Feb 2022 
		if (base64Context && base64Context.startsWith('1.')) {
			base64Context = base64Context.substring(2);
		}
		var addressableContext = base64Context
			? JSON.parse(window.atob(base64Context))
			: null;

		if (
			currentPageReference != null &&
			currentPageReference.state != null &&
			addressableContext &&
			addressableContext.attributes.objectApiName == 'Account'
		) {
			this.isCallFromAccount = true;
			this.parentAccountId = addressableContext.attributes.recordId;
		} else {
			this.isCallFromAccount = false; //Checking change from true to false
			this.parentAccountId = null;
		}

		//auto populating on contact creation form - starts
		if (currentPageReference.state.defaultFieldValues) {
			const dfvObject = decodeDefaultFieldValues(
				currentPageReference.state.defaultFieldValues
			);
			this.contactDetail.FirstName = dfvObject.FirstName;
			this.contactDetail.LastName = dfvObject.LastName;

			this.contactDetail.GlobalPartyId = dfvObject.GlobalPartyId;
			this.contactDetail.Physician_Registration_No__c =
				dfvObject.Physician_Registration_No__c;
			this.contactDetail.Phone = dfvObject.Phone;
			this.contactDetail.MobilePhone = dfvObject.MobilePhone;
			this.contactDetail.Extension__c = dfvObject.Extension__c;
			this.contactDetail.Email = dfvObject.Email;

			this.contactDetail.MailingStreet = dfvObject.MailingStreet;
			this.contactDetail.MailingCity = dfvObject.MailingCity;
			this.contactDetail.MailingPostalCode = dfvObject.MailingPostalCode;
			this.contactDetail.MailingState = dfvObject.MailingState;
			this.contactDetail.MailingCountry = dfvObject.MailingCountry;

			this.contactDetail.MailingStateCode = dfvObject.MailingStateCode;
			this.contactDetail.MailingCountryCode = dfvObject.MailingCountryCode;
			this.contactDetail.syncAddress = dfvObject.Sync_Address_With_Account__c; //updated 9-29-2021

			if (dfvObject.MailingCountryCode) {
				this.setMailingStates();
			}
		}
		this.setDefaultFieldValues();
	}

	@wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
	contactInfo;

	@wire(getPicklistValues, {
		recordTypeId: '$recordTypeId',
		fieldApiName: MAILING_COUNTRY_CODE_FIELD
	})
	countryList({ data }) {
		if (data) {
			this.mailingCountries = [...data.values];
		}
	}

	@wire(getPicklistValues, {
		recordTypeId: '$recordTypeId',
		fieldApiName: MAILING_STATE_CODE_FIELD
	})
	stateList({ error, data }) {
		if (data) {
			this.allMailingStates = data;
		}
	}

	setActiveSections() {
		this.layoutSections.forEach((sectionHeading) => {
			this.activeSections.push(sectionHeading.id);
		});
	}

	/*--------- 05 Aug, 2021 - Get page layout section using LIGHTNING-RECORD-EDIT-FORM (LDS) - START ---------*/
	handleLoad(event) {
		//Added 22 Sep, 2021 - To prevent form rendering
		if (this.hasLoaded) return;
		this.hasLoaded = true;
		this.showDQMOdal = false; //for DQ Popup

		event.preventDefault();
		let contactLayoutInfo = JSON.parse(JSON.stringify(event.detail.layout));
		let contactData = JSON.parse(JSON.stringify(this.contactInfo));

		this.layoutSections = contactLayoutInfo.sections;
		this.recordData = contactLayoutInfo;
		this.contactInfoFields = Object.entries(contactData.data.fields);

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
		let temp = [];


		for (let i = 0; i < this.layoutSections.length; i++) {
			if (i == 0 || this.layoutSections[i].useHeading == true) {
				if (this.layoutSections[i].heading != 'Data Quality') {
					temp.push(this.layoutSections[i]);
				}


			}
		}

		// This is a form to create a new contact record, so we don't already have a field value to create the record

		let dependentList = [];
		let dependentMap = [];

		this.contactInfoFields.forEach((r) => {
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
			s.isAddressField = s.heading == this.LABEL.ADDRESS_INFORMATION;
			s.layoutRows.forEach((r) => {
				r.layoutItems.forEach((i) => {
					i.isNameField = i.label == this.LABEL.NAME;
					i.isMailingAddressField = i.label == this.LABEL.MAILING_ADDRESS;
					i.jobFunctionField = i.label == 'Job Function';
					i.physicianIndependenceField = i.label == 'Physician Independence';

					//Added on 25 Aug 2021 Hide Contact Origin Field on New/Edit Page Layout
					i.isContactOriginField = i.label == 'Contact Origin';

					if (s.heading == this.LABEL.SYSTEM_INFORMATION) {
						i.isSystemInformationSection = true;
						if (i.label == this.LABEL.CONTACT_RECORD_TYPE) {
							i.isRecordType = true;
						}
					} else {
						i.isSystemInformationSection = false;
					}

					if (i.label == 'Sync Address With Account') {
						r.layoutItems.splice(i, 1);
					}

					i.layoutComponents.forEach((p) => {
						//handle formula fields
						var apiName = p.apiName;
						this.fieldApiName = apiName;
						if (dependentList.includes(p.apiName)) {
							i.isControllingField = true;
							i.controllingFields = '';
							dependentMap.forEach((t) => {
								if (t.key == p.apiName) {
									i.controllingFields += t.value + ',';
								}
							});
							i.controllingFields = i.controllingFields.slice(0, -1);
						}
					});
				});
			});
		});

		this.layoutSections = temp;

		//auto populating on contact creation form - starts

		this.setDefaultFieldValues();
		//auto populating on contact creation form - ends
	}
	/* ------------ END ------------ */

	handleMailingCountryOneChange(event) {
		let key = this.allMailingStatesOne.controllerValues[event.target.value];
		let filteredPhysicianIndependence = this.allMailingStatesOne.values.filter(
			(opt) => opt.validFor.includes(key)
		);
		this.mailingStatesOne = filteredPhysicianIndependence.length
			? [DEFAULT_PICKLIST_VALUE, ...filteredPhysicianIndependence]
			: [];
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

	handleCountryChange(event) {
		this.contactDetail.MailingCountryCode = event.target.value;

		let key = this.allMailingStates.controllerValues[event.target.value];
		let filteredStates = this.allMailingStates.values.filter((opt) =>
			opt.validFor.includes(key)
		);
		this.mailingStates = [...filteredStates];
	}

	setMailingStates() {
		window.setTimeout(
			(self) => {
				let key =
					this.allMailingStates.controllerValues[
					self.contactDetail.MailingCountryCode
					];
				let filteredStates = self.allMailingStates.values.filter((opt) =>
					opt.validFor.includes(key)
				);
				self.mailingStates = [...filteredStates];
			},
			2000,
			this
		);
	}

	addressChanged(event) {
		event.target.value = event.target.country;
		this.updatedAddressDetails.MailingStreet = event.target.street;
		this.updatedAddressDetails.MailingCity = event.target.city;
		this.updatedAddressDetails.MailingPostalCode = event.target.postalCode;
		this.updatedAddressDetails.MailingStateCode = event.target.province;
		this.updatedAddressDetails.MailingCountryCode = event.target.country;
		this.updatedAddressDetails.syncAddress = event.target.syncAddress;
		this.handleCountryChange(event);
	}

	handleInputChange(event) {
		this.contactDetail[event.target.name] = event.target.value;
	}

	handleLocationSelection(event) {
		let selectedLocation = JSON.parse(JSON.stringify(event.detail));
		this.contactDetail['Address_Number__c'] = selectedLocation.length
			? selectedLocation[0].id
			: null;
	}

	handleAddressSelection(event) {
		this.addressSelectionType = event.target.value;
		this.selectedAddressSelectionType = event.target.value;
		this.toggleAddressFieldSection = this.addressSelectionType == 'Manual';

		if (this.selectedAddressSelectionType == 'Manual') {
			this.contactDetail.MailingStreet = null;
			this.contactDetail.MailingCity = null;
			this.contactDetail.MailingPostalCode = null;
			this.contactDetail.MailingStateCode = null;
			this.contactDetail.MailingCountryCode = null;
			this.contactDetail.syncAddress = false;
		} else if (
			this.selectedAddressSelectionType == 'Sync Address from Global Profile'
		) {
			this.contactDetail.MailingStreet = this.contactData.MailingStreet;
			this.contactDetail.OtherStreet = this.contactData.OtherStreet;
			this.contactDetail.MailingCity = this.contactData.MailingCity;
			this.contactDetail.MailingPostalCode = this.contactData.MailingPostalCode;
			this.contactDetail.MailingCountry = this.contactData.MailingCountry;
			this.contactDetail.MailingState = this.contactData.MailingState;
			this.contactDetail.syncAddress = false;
		}
	}

	setDefaultFieldValues() {
		window.setTimeout(
			(self) => {
				const inputFields = self.template.querySelectorAll(
					'lightning-input-field'
				);
				if (inputFields) {
					inputFields.forEach((field) => {
						if (this.contactData && this.contactData != null) {
							if (field.fieldName == 'FirstName')
								field.value = this.contactData.FirstName;
							if (field.fieldName == 'LastName')
								field.value = this.contactData.LastName;
							if (field.fieldName == 'GlobalPartyId')
								field.value = this.contactData.GlobalPartyId;
							if (field.fieldName == 'Physician_Registration_No__c')
								field.value = this.contactData.Physician_Registration_No__c;
							if (field.fieldName == 'Phone')
								field.value = this.contactData.Phone;
							if (field.fieldName == 'MobilePhone')
								field.value = this.contactData.MobilePhone;
							if (field.fieldName == 'Email')
								field.value = this.contactData.Email;
							if (field.fieldName == 'Extension__c')
								field.value = this.contactData.Extension__c;
							if (field.fieldName == 'Contact_Origin__c')
								field.value = 'Contact Tab';
						}
						if (field.fieldName == 'AccountId') {
							if (self.isCallFromAccount && self.parentAccountId != '') {
								field.value = self.parentAccountId;
							}
						}
					});
				}

				if (this.addressSelectionType == 'Sync Address from Global Profile') {
					this.contactDetail.MailingStreet = this.contactData.MailingStreet;
					this.contactDetail.OtherStreet = this.contactData.OtherStreet;
					this.contactDetail.MailingCity = this.contactData.MailingCity;
					this.contactDetail.MailingPostalCode =
						this.contactData.MailingPostalCode;
					this.contactDetail.MailingCountry = this.contactData.MailingCountry;
					this.contactDetail.MailingState = this.contactData.MailingState;
					this.contactDetail.syncAddress = this.contactData.syncAddress;
				}
				if (this.selectedAddressSelectionType == 'Manual') {
					/* Added 11/8/2021 */
					this.contactDetail.MailingStreet = null;
					this.contactDetail.MailingCity = null;
					this.contactDetail.MailingPostalCode = null;
					this.contactDetail.MailingStateCode = null;
					this.contactDetail.MailingCountryCode = null;
					this.contactDetail.syncAddress = false;
				}
			},
			2000,
			this
		);
	}

	// Validation Section, this checks the validation rules
	validateFields(event) {
		this.isErrorPopup = false;
		this.errorMessages = [];
		this.warningMessages = { message: null, data: null };
		let errors = [];

		try {
			const allValid = [
				...this.template.querySelectorAll('lightning-input')
			].reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				if (!inputCmp.checkValidity()) {
					errors.push(inputCmp.label);
				}
				return validSoFar && inputCmp.checkValidity();
			}, true);

			let allInputsAreFilled = true;
			[...this.template.querySelectorAll('lightning-input-field')].forEach(
				(element) => {
					element.reportValidity();
					// Added on 17 Aug, 2020 -->  !element.reportValidity()
					if (
						(element.required && element.value == null) ||
						!element.reportValidity()
					) {
						allInputsAreFilled = false;
						if (
							this.contactInfo &&
							this.contactInfo.data &&
							this.contactInfo.data.fields.hasOwnProperty(element.fieldName)
						) {
							let fieldLabel =
								this.contactInfo.data.fields[element.fieldName].label;
							errors.push(fieldLabel);
						} else {
							errors.push(element.fieldName);
						}
					}
				}
			);
			if (allValid && allInputsAreFilled) {
				this.isSpinner = true;
				this.errorMessages = [];

				/* START: Here we are validating email, phone, and address with DQ System API */

				/* --------------- END ---------------*/

				this.handleOnSubmit(event.target.name);
			} else {
				this.errorMessages = errors;
				this.isErrorPopup = true;
			}
		} catch (error) {
			this.isSpinner = false;
		}
	}

	handleSyncAddress(syncAddress) {
		if (syncAddress == false) {
			fields.syncAddress = false;
		}
	}
	// End of validation Rules
	handleOnSubmit(whichButtonClicked) {
		if (whichButtonClicked == 'Save') {
			this.whichButtonWasClicked = this._WhichButtonWasLastClicked = 'Save'; // Updated on 18 Jan 2022 - SFSC - 6173
			this.template.querySelector('.save-button').click();
		} else {
			this.whichButtonWasClicked = this._WhichButtonWasLastClicked = 'SaveAndNew'; // Updated on 18 Jan 2022 - SFSC - 6173
			this.template.querySelector('.save-and-new-button').click();
		}
	}

	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting

		const fields = event.detail.fields ? event.detail.fields : {}; //Updated on 18 Jan 2022
		//Get Account Address if account is selected.
		this.selectedAccountId = fields.hasOwnProperty('AccountId')
			? fields.AccountId
			: null;

		if (this.selectedAddressSelectionType == '') {
			this.selectedAddressSelectionType = this.addressSelectionType;
		}
		// Copy Address from account
		if (
			this.selectedAddressSelectionType == 'Sync Address from Account' &&
			fields.AccountId != null
		) {
			this.getAccountData().then((response) => {
				this.accountData = response;
				fields.MailingCountryCode = this.accountData.BillingCountryCode;
			});
		} else {
			// Added on 4 Aug 2021 - fixed address issue
			this.contactDetail.MailingStreet = this.contactDetail.MailingStreet
				? this.contactDetail.MailingStreet +
				(this.contactDetail.Apt_Floor_Suit
					? `\n${this.contactDetail.Apt_Floor_Suit}`
					: '')
				: null;
			if (
				this.selectedAddressSelectionType == 'Sync Address from Global Profile'
			) {
				fields.MailingState = this.contactDetail.MailingState;
				fields.MailingCountry = this.contactDetail.MailingCountry;
				fields.Sync_Address_With_Account__c =
					this.contactDetail.Sync_Address_With_Account__c = false;
			} else {
				this.contactDetail.MailingStreet =
					this.updatedAddressDetails.MailingStreet;
				this.contactDetail.MailingCity = this.updatedAddressDetails.MailingCity;
				this.contactDetail.MailingPostalCode =
					this.updatedAddressDetails.MailingPostalCode;
				this.contactDetail.MailingStateCode =
					this.updatedAddressDetails.MailingStateCode;
				this.contactDetail.MailingCountryCode =
					this.updatedAddressDetails.MailingCountryCode;
				fields.MailingCountryCode =
					this.contactDetail.MailingCountryCode != 'none'
						? this.contactDetail.MailingCountryCode
						: null;
				fields.MailingStateCode =
					this.contactDetail.MailingStateCode != 'none'
						? this.contactDetail.MailingStateCode
						: null;
				fields.Sync_Address_With_Account__c =
					this.contactDetail.Sync_Address_With_Account__c = false;
			}
			fields.MailingCity = this.contactDetail.MailingCity;
			fields.MailingPostalCode = this.contactDetail.MailingPostalCode;
			fields.MailingStreet = this.contactDetail.MailingStreet;
			this.contactDetail.Sync_Address_With_Account__c = false;
		}

		this.contactDetail.Contact_Origin__c = 'Contact Tab';
		fields.Contact_Origin__c = 'Contact Tab';
		this.contactDetail.GlobalPartyId = this.contactData.GlobalPartyId;
		fields.GlobalPartyId = this.contactData.GlobalPartyId;

		if (this.whichButtonWasClicked != 'ContinueToSave') {
			this.contactDetail = fields;
		}

		if (this.whichButtonWasClicked == 'ContinueToSave') {
			this.insertContact(JSON.parse(JSON.stringify(fields)));
		} else {
			//SFSC-6173 -   starts
			this.showDQMOdal = true;

			let email = this.contactDetail.Email;
			let secondaryEmail = this.contactDetail.Secondary_Email__c;
			let phone = this.contactDetail.Phone;
			let mobilePhone = this.contactDetail.MobilePhone;

			if (email != null && email != '') {
				this.dqFieldsToValidate.push('Email');
			}

			if (secondaryEmail != null && secondaryEmail != '') {
				this.dqFieldsToValidate.push('SecondaryEmail');
			}

			if (phone != null && phone != '') {
				this.dqFieldsToValidate.push('Phone');
			}

			if (mobilePhone != null && mobilePhone != '') {
				this.dqFieldsToValidate.push('MobilePhone');
			}

			if (this.selectedAddressSelectionType == 'Manual') {
				if (
					this.isNotBlank(this.contactDetail.MailingStreet) ||
					this.isNotBlank(this.contactDetail.MailingCity) ||
					this.isNotBlank(this.contactDetail.MailingCountryCode) ||
					this.isNotBlank(this.contactDetail.MailingStateCode) ||
					this.isNotBlank(this.contactDetail.MailingPostalCode)
				) {
					this.dqFieldsToValidate.push('Address');
				}
			}

			var modalLoading = setInterval(() => {
				console.log('1');
				var modal = this.template.querySelector('c-d-q-validation');
				if (modal != null) {
					clearInterval(modalLoading);
					modal.validateDQServices();
				}
			}, 100);

		}

		//SFSC-6173 - ends
	}

	formatDate(date) {
		let d = new Date(date),
			month = '' + (d.getMonth() + 1),
			day = '' + d.getDate(),
			year = d.getFullYear();

		if (month.length < 2) month = '0' + month;
		if (day.length < 2) day = '0' + day;

		return [year, month, day].join('-');
	}

	insertContact(data) {
		this.isSpinner = true;
		this.isErrorPopup = false;
		let duplicateContact = JSON.parse(JSON.stringify(data));

		/* fill the verification status and date of the DQ system */
		duplicateContact['Email_Verification_Status__c'] =
			this.contactDetail.hasOwnProperty('Email_Verification_Status__c')
				? this.contactDetail.Email_Verification_Status__c
				: null;
		duplicateContact['Email_Verification_Date__c'] =
			this.contactDetail.hasOwnProperty('Email_Verification_Date__c')
				? this.contactDetail.Email_Verification_Date__c
				: null;
		duplicateContact['Secondary_Email_Verification_Status__c'] =
			this.contactDetail.hasOwnProperty(
				'Secondary_Email_Verification_Status__c'
			)
				? this.contactDetail.Secondary_Email_Verification_Status__c
				: null;
		duplicateContact['Secondary_Email_Verification_Date__c'] =
			this.contactDetail.hasOwnProperty('Secondary_Email_Verification_Date__c')
				? this.contactDetail.Secondary_Email_Verification_Date__c
				: null;
		duplicateContact['Phone_Verification_Status__c'] =
			this.contactDetail.hasOwnProperty('Phone_Verification_Status__c')
				? this.contactDetail.Phone_Verification_Status__c
				: null;
		duplicateContact['Phone_Verification_Date__c'] =
			this.contactDetail.hasOwnProperty('Phone_Verification_Date__c')
				? this.contactDetail.Phone_Verification_Date__c
				: null;
		duplicateContact['Mobile_Phone_Verification_Status__c'] =
			this.contactDetail.hasOwnProperty('Mobile_Phone_Verification_Status__c')
				? this.contactDetail.Mobile_Phone_Verification_Status__c
				: null;
		duplicateContact['Mobile_Phone_Verification_Date__c'] =
			this.contactDetail.hasOwnProperty('Mobile_Phone_Verification_Date__c')
				? this.contactDetail.Mobile_Phone_Verification_Date__c
				: null;
		duplicateContact['Address_Verification_Status__c'] =
			this.contactDetail.hasOwnProperty('Address_Verification_Status__c')
				? this.contactDetail.Address_Verification_Status__c
				: null;
		duplicateContact['Address_Verification_Date__c'] =
			this.contactDetail.hasOwnProperty('Address_Verification_Date__c')
				? this.contactDetail.Address_Verification_Date__c
				: null;
		// Prevents Record Type Override after duplication check
		duplicateContact.RecordTypeId = this.recordTypeId;

		insertDuplicateContact({ duplicateContact })
			.then((result) => {
				this.isSpinner = false;
				if (result.isSuccuss) {
					//show success message only if data is valid
					if (this.inValidData != 'invalidData') {
						if (this.inValidData == 'APIException' || this.inValidData == '') {
							const showDataUpdatedEvt = new ShowToastEvent({
								title: 'Success',
								message: 'Contact has been created successfully.',
								variant: 'success'
							});
							this.dispatchEvent(showDataUpdatedEvt);
						} else if (this.inValidData == 'DQ_CALLOUT') {
							this.showCorrectDataToastMessage();
						}
					} else if (this.inValidData == 'invalidData') {
						this.showInvalidDataToastMessage();
					}
					//this.navigateToRecordViewPage(result.message);
					// Added on 18 Jan 2022  - SFSC - 6173
					if (this.whichButtonWasClicked && (this.whichButtonWasClicked == 'SaveAndNew' || this._WhichButtonWasLastClicked == 'SaveAndNew')) {
						this.whichButtonWasClicked = this._WhichButtonWasLastClicked = null;
						this.navigateToNewRecordPage();
					} else {
						this.navigateToRecordViewPage(result.message);
					}
				} else {
					this.dispatchEvent(
						new ShowToastEvent({
							title: 'Error',
							message: result.message,
							variant: 'error'
						})
					);
				}
			})
			.catch((error) => {
				this.isSpinner = false;
			});
	}

	handleContinueToSave() {
		this.whichButtonWasClicked = 'ContinueToSave';
		this.template.querySelector('.continue-save-button').click();
	}

	handleSucess(event) {
		this.isSpinner = false;
		//show success message only if data is valid
		if (this.inValidData != 'invalidData') {
			if (this.inValidData == 'APIException' || this.inValidData == '') {
				const showDataUpdatedEvt = new ShowToastEvent({
					title: 'Success',
					message: 'Contact has been created successfully.',
					variant: 'success'
				});
				this.dispatchEvent(showDataUpdatedEvt);
			} else if (this.inValidData === 'DQ_CALLOUT') {
				//SFSC - 6173 - changed flag from "validData" to "DQ_Callout"
				this.showCorrectDataToastMessage();
			} else if (this.inValidData == 'validData') {
				this.showCorrectDataToastMessage();
			}
		} else if (this.inValidData == 'invalidData') {
			//show invalid message only if data is invalid
			this.showInvalidDataToastMessage();
		}
		//Updated on 18 Jan 2022 - SFSC - 6173
		if (this.whichButtonWasClicked && (this.whichButtonWasClicked == 'SaveAndNew' || this._WhichButtonWasLastClicked == 'SaveAndNew')) {
			this.whichButtonWasClicked = this._WhichButtonWasLastClicked = null;
			this.navigateToNewRecordPage();
			this.warningMessages = { message: null, data: null }; //1-20-2022 - SFSC - 6173
		} else {
			this.navigateToRecordViewPage(event.detail.id);
		}
	}

	handleError(event) {
		this.isSpinner = false;
		this.showModal_Invalid = false;
		let formErrorDetails = JSON.parse(JSON.stringify(event.detail));
		this.isErrorPopup = true;
		let errors = [];
		let warnings = { message: null, data: null };
		if (formErrorDetails.hasOwnProperty('output')) {
			if (formErrorDetails.output.hasOwnProperty('fieldErrors')) {
				Object.entries(formErrorDetails.output.fieldErrors).forEach(
					([key, value]) => {
						value.forEach((obj) => {
							errors.push(`${obj.fieldLabel}: ${obj.message}`);
						});
					}
				);
			}
			if (
				formErrorDetails.output.hasOwnProperty('errors') &&
				formErrorDetails.output.errors.length
			) {
				formErrorDetails.output.errors.forEach((fielderror) => {
					if (fielderror.errorCode === 'DUPLICATES_DETECTED') {
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

	//SFSC - 7070 - 27/01/2022 commenting starts
	/*
handleReset() {
	const inputFields = this.template.querySelectorAll('lightning-input-field');
	if (inputFields) {
		inputFields.forEach((field) => {
			field.reset();
		});
	}	

	//window.history.back();
}*/
	//SFSC - 7070 -  27/01/2022 commenting ends

	handleVisibilityOfErrorPopup() {
		this.isErrorPopup = !this.isErrorPopup;
	}

	handleViewRecordDatail(event) {
		this.navigateToRecordViewPage(event.currentTarget.dataset.id);
	}

	navigateToRecordViewPage(recordId) {
		window.location.href = `/lightning/r/Contact/${recordId}/view`;
	}

	navigateToNewRecordPage() {
		this.showContactCreateModal = false; //SFSC - 7070 - 27/01/2022 - //flag to display contact record selection page after clicking on save and new
		//SFSC - 7070  - 27/01/2022- adding starts
		if (this.isGlobalSearchPage) {
			this[NavigationMixin.Navigate]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: 'Contact',
					actionName: 'new'
				}, state: { // Added on 2 Feb 2022 - SFSC - 7070
					c__globalSearch: 'true'
				}
			});
		}
		else if (this.inContextOfReference) {
			this[NavigationMixin.Navigate]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: 'Contact',
					actionName: 'new'
				}, state: { // Added on 2 Feb 2022 - SFSC - 7070
					inContextOfRef: this.inContextOfReference,
				}
			});
		}

		eval("$A.get('e.force:refreshView').fire();");
		//SFSC - 7070 - 27/01/2022 adding ends
	}

	handleDependenciesSelection() {
		if (this.checkDependentFieldType) {
			let selectedJobFunction = this.template.querySelector(
				'[data-id="JobFunctionCombobox"]'
			).value;
			let selectedPhysicianIndependence = this.template.querySelector(
				'[data-id="PhysicianIndependenceCombobox"]'
			).value;
			this.contactDetail.Job_Function__c =
				selectedJobFunction && selectedJobFunction != 'none'
					? selectedJobFunction
					: null;
			this.contactDetail.Physician_Independence__c =
				selectedPhysicianIndependence && selectedPhysicianIndependence != 'none'
					? selectedPhysicianIndependence
					: null;
		} else {
			let mailingCountry = this.template.querySelector(
				'[data-id="MailingCountryCombobox"]'
			).value;
			let mailingState = this.template.querySelector(
				'[data-id="MailingStateCombobox"]'
			).value;
		}
		window.setTimeout(
			(self) => {
				self.isViewAllDependentModal = false;
			},
			100,
			this
		);
	}

	closeDependenciesModal() {
		this.isViewAllDependentModal = false;
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
				? 'slds-popover slds-popover_error slds-nubbin_bottom-left'
				: 'slds-popover slds-popover_warning  slds-nubbin_bottom-left') +
			' popover-custom-width'
		);
	}

	get recordTypeName() {
		return this.contactInfo &&
			this.contactInfo.data &&
			this.contactInfo.data.recordTypeInfos &&
			this.contactInfo.data.recordTypeInfos.hasOwnProperty(this.recordTypeId)
			? this.contactInfo.data.recordTypeInfos[this.recordTypeId].name
			: this.recordTypeId;
	}

	get addressSelectionOptions() {
		let contactData = this.contactData;
		let mailingAddress;
		if (contactData != undefined) {
			mailingAddress =
				contactData.MailingStreet != null ||
					contactData.OtherStreet != null ||
					contactData.MailingState != null ||
					contactData.MailingPostalCode != null ||
					contactData.MailingCountry != null ||
					contactData.MailingCity != null
					? true
					: false;
		}
		if (mailingAddress) {
			this.addressSelectionType = 'Sync Address from Global Profile';
			return [
				{
					label: 'Sync Address from Account',
					value: 'Sync Address from Account'
				},
				{
					label: 'Sync Address from Global Profile',
					value: 'Sync Address from Global Profile'
				},
				{ label: 'Manual', value: 'Manual' }
			];
		} else {
			this.addressSelectionType = 'Sync Address from Account';
			return [
				{
					label: 'Sync Address from Account',
					value: 'Sync Address from Account'
				},
				{ label: 'Manual', value: 'Manual' }
			];
		}
	}

	get checkDependentFieldType() {
		return this.dependentFieldName === 'Job Function';
	}

	get isMailingStatesDisabled() {
		return !this.mailingStatesOne || !this.mailingStatesOne.length;
	}

	get isPhysicianIndependenceDisabled() {
		return (
			!this.physicianIndependenceOptions ||
			!this.physicianIndependenceOptions.length
		);
	}

	closeModal() {
		console.log('inside close123 ' + this.contactRecordId);
		//starts - SFSC -  7070 -01/02/2022 navigate to record page when user comes on contact edit form and hits save and new and clicks on "Cancel" button of contact creation form
		this.showContactCreateModal = false;		
		if (this.isGlobalSearchPage) { //06 Feb
			this.raiseEvent('closecontactcreatemodal', this.contactData); //SFSC - 7070 - added to contact modal
			this[NavigationMixin.Navigate]({
				type: 'standard__navItemPage',
				attributes: {
					apiName: 'Global_Profile_Search',
				}
			});
			//this.raiseEvent('manualrendered', this.contactData);
		}
		// Added on 2 Feb 2022 - Navigate to Go Back  - SFSC - 7070 - starts
		else if (this.inContextOfReference) {
			let base64Context = this.inContextOfReference;
			if (base64Context && base64Context.startsWith('1.')) {
				base64Context = base64Context.substring(2);
			}
			let addressableContext = base64Context ? JSON.parse(window.atob(base64Context)) : null;
			console.log('AddressableContext : ', addressableContext);
			if (addressableContext) {
				this[NavigationMixin.Navigate](addressableContext);
			}
			this.raiseEvent('manualrendered', this.contactData);
		}
		// Added on 2 Feb 2022 - Navigate to Go Back  - SFSC - 7070 - ends

		else if (this.isComingFrom360SearchPage) { // Added on 4 Feb 2022
			this[NavigationMixin.Navigate]({
				type: 'standard__navItemPage',
				attributes: {
					apiName: 'Global_Profile_Search',
				}
			});
			this.raiseEvent('manualrendered', this.contactData);
		}


	}
	// Duplicate Modal windows
	handleViewDuplicatesModal() {
		this.isViewDuplicatesModal = !this.isViewDuplicatesModal;
	}

	handleViewAllDependentModal(event) {
		this.dependentFieldName = event.currentTarget.dataset.fieldName;
		this.isViewAllDependentModal = true;
	}

	handleViewAllDependentModalClose() {
		this.isViewAllDependentModal = false;
	}

	raiseEvent(name, args) {
		const customEvent = new CustomEvent(name, {
			detail: args
		});

		this.dispatchEvent(customEvent);
	}

	isNotBlank(value) {
		return value != null && value != '' && value.trim().length > 0;
	}

	closeContactCreateModal() {
		window.history.back();
		eval("$A.get('e.force:refreshView').fire();");
	}

	showCorrectDataToastMessage() {
		const showCorrectDataToastMessageEvt = new ShowToastEvent({
			title: 'Success',
			message: 'Contact Created and Data Validated',
			variant: 'success'
		});
		this.dispatchEvent(showCorrectDataToastMessageEvt);
	}

	showInvalidDataToastMessage() {
		const showInvalidDataToastMessageEvt = new ShowToastEvent({
			title: 'Warning',
			message: 'Contact Created and Data Invalid',
			variant: 'warning'
		});
		this.dispatchEvent(showInvalidDataToastMessageEvt);
	}

	//show success toast message and save data
	saveData() {

		this.template
			.querySelector('lightning-record-edit-form')
			.submit(this.contactDetail);
	}

	calculateTodaysDate() {
		//calculate today's date
		var today = new Date();
		var dd = today.getDate();
		var mm = today.getMonth() + 1;
		var yyyy = today.getFullYear();

		today = yyyy + '-' + mm + '-' + dd;
		return today;
	}

	resetAll() {
		this.inValidData = '';
	}

	getAccountData() {
		return new Promise((resolve, reject) => {
			getAccountDetails({ accountId: this.selectedAccountId })
				.then((result) => {
					resolve(result);
				})
				.catch((error) => {
					reject(error);
				});
		});
	}

	//handle events for DQ modal  - SFSC-6173 - starts
	dqValidationCompleted(event) {
		this.contactDetail = event.detail;
		this.inValidData = event.detail.inValidData;
		this.saveData();

	}

	closeDQPopupModal(event) {
		this.showDQMOdal = event.detail;
		this.isSpinner = false;

	}
	//SFSC-7116 31-01-2022 Added key press event to prevent record submission on "Enter" key press
	handleKeyPress(component) {
		if (component.which == 13) {
			component.preventDefault();
		}
	}
}