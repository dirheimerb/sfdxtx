/* eslint-disable vars-on-top */
/**
 * Created by bdirh on 12/27/2021.
 */

import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUnifiedProfile from '@salesforce/apex/CDP_DisplayUnifiedProfile.displayUnifiedProfile';
import adoptContactDetails from '@salesforce/apex/CDP_DisplayUnifiedProfile.adoptContactDetails';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import ID_FIELD from '@salesforce/schema/Contact.Id';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import MOBILEPHONE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import SECONDARYEMAIL_FIELD from '@salesforce/schema/Contact.Secondary_Email__c';
import { getRecord } from 'lightning/uiRecordApi';


// eslint-disable-next-line no-unused-vars
const QUERY_PARAMS =
    "{ \"sql\" : \"SELECT OccuranceCnt, Id, ContactPoint, ContactPointType, SourceRecord, CreatedDate, LastModifiedDate FROM ( SELECT COUNT(*) as OccuranceCnt, UnifiedIndividual__dlm.ssot__Id__c AS Id, 'INDIVIDUAL' as ContactPointType, UnifiedIndividual__dlm.ssot__FirstName__c || ',' || UnifiedIndividual__dlm.ssot__LastName__c AS ContactPoint, IndividualIdentityLink__dlm.ssot__DataSourceId__c || ',' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || IndividualIdentityLink__dlm.SourceRecordId__c AS SourceRecord,  cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR) AS CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) AS LastModifiedDate FROM UnifiedIndividual__dlm LEFT JOIN IndividualIdentityLink__dlm ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedIndividual__dlm.ssot__Id__c, UnifiedIndividual__dlm.ssot__FirstName__c || ',' || UnifiedIndividual__dlm.ssot__LastName__c, IndividualIdentityLink__dlm.ssot__DataSourceId__c || ',' || IndividualIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || IndividualIdentityLink__dlm.SourceRecordId__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c as VARCHAR), cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c as VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointAddress__dlm.ssot__PartyId__c AS Id, 'ADDRESS' as ContactPointType, UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || ',' || UnifiedContactPointAddress__dlm.ssot__CityId__c || ',' || UnifiedContactPointAddress__dlm.ssot__StateProvinceId__c || ',' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || ',' || UnifiedContactPointAddress__dlm.ssot__CountryId__c AS ContactPoint, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointAddressIdentityLink__dlm.SourceRecordId__c AS SourceRecord,cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c As VARCHAR) AS CreatedDate, cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) AS LastModifiedDate FROM UnifiedContactPointAddress__dlm LEFT JOIN ContactPointAddressIdentityLink__dlm ON UnifiedContactPointAddress__dlm.ssot__Id__c = ContactPointAddressIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointAddress__dlm.ssot__PartyId__c, UnifiedContactPointAddress__dlm.ssot__AddressLine1__c || ',' || UnifiedContactPointAddress__dlm.ssot__CityId__c || ',' || UnifiedContactPointAddress__dlm.ssot__StateProvinceId__c || ',' || UnifiedContactPointAddress__dlm.ssot__PostalCodeId__c || ',' || UnifiedContactPointAddress__dlm.ssot__CountryId__c, ContactPointAddressIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointAddressIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointAddressIdentityLink__dlm.SourceRecordId__c, cast(UnifiedContactPointAddress__dlm.ssot__CreatedDate__c as VARCHAR), cast(UnifiedContactPointAddress__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointEmail__dlm.ssot__PartyId__c AS Id, 'EMAIL' AS ContactPointType, UnifiedContactPointEmail__dlm.ssot__EmailAddress__c AS ContactPoint, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointEmailIdentityLink__dlm.SourceRecordId__c AS SourceRecord, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM UnifiedContactPointEmail__dlm LEFT JOIN ContactPointEmailIdentityLink__dlm ON UnifiedContactPointEmail__dlm.ssot__Id__c = ContactPointEmailIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointEmail__dlm.ssot__PartyId__c, UnifiedContactPointEmail__dlm.ssot__EmailAddress__c, ContactPointEmailIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointEmailIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointEmailIdentityLink__dlm.SourceRecordId__c, cast(UnifiedContactPointEmail__dlm.ssot__CreatedDate__c As VARCHAR) , cast(UnifiedContactPointEmail__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,'SECONDARY EMAIL' AS ContactPointType,unifiedindividual__dlm.Secondary_Email_c__c AS ContactPoint,individualidentitylink__dlm.ssot__datasourceid__c || ','|| individualidentitylink__dlm.ssot__datasourceobjectid__c || ','|| individualidentitylink__dlm.sourcerecordid__c AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.Secondary_Email_c__c,individualidentitylink__dlm.ssot__datasourceid__c || ',' || individualidentitylink__dlm.ssot__datasourceobjectid__c || ',' || individualidentitylink__dlm.sourcerecordid__c,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR), cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, ssot__PartyIdentification__dlm.ssot__PartyId__c AS Id, 'PARTYID' AS ContactPointType, ssot__PartyIdentification__dlm.ssot__Name__c || ',' || ssot__PartyIdentification__dlm.ssot__IdentificationNumber__c AS ContactPoint, PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || ',' || PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || PartyIdentificationIdentityLink__dlm.SourceRecordId__c AS SourceRecord,cast(ssot__PartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate,cast(ssot__PartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM ssot__PartyIdentification__dlm LEFT JOIN PartyIdentificationIdentityLink__dlm ON ssot__PartyIdentification__dlm.ssot__Id__c = PartyIdentificationIdentityLink__dlm.UnifiedRecordId__c GROUP BY ssot__PartyIdentification__dlm.ssot__PartyId__c, ssot__PartyIdentification__dlm.ssot__Name__c || ',' || ssot__PartyIdentification__dlm.ssot__IdentificationNumber__c, PartyIdentificationIdentityLink__dlm.ssot__DataSourceId__c || ',' || PartyIdentificationIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || PartyIdentificationIdentityLink__dlm.SourceRecordId__c, cast(ssot__PartyIdentification__dlm.ssot__CreatedDate__c As VARCHAR),cast(ssot__PartyIdentification__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT COUNT(*) AS OccuranceCnt, UnifiedContactPointPhone__dlm.ssot__PartyId__c AS Id, 'PHONE' AS ContactPointType, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c AS ContactPoint, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c AS SourceRecord,cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM UnifiedContactPointPhone__dlm LEFT JOIN ContactPointPhoneIdentityLink__dlm ON UnifiedContactPointPhone__dlm.ssot__Id__c = ContactPointPhoneIdentityLink__dlm.UnifiedRecordId__c GROUP BY UnifiedContactPointPhone__dlm.ssot__PartyId__c, UnifiedContactPointPhone__dlm.ssot__FormattedE164PhoneNumber__c, ContactPointPhoneIdentityLink__dlm.ssot__DataSourceId__c || ',' || ContactPointPhoneIdentityLink__dlm.ssot__DataSourceObjectId__c || ',' || ContactPointPhoneIdentityLink__dlm.SourceRecordId__c, cast(UnifiedContactPointPhone__dlm.ssot__CreatedDate__c As VARCHAR),cast(UnifiedContactPointPhone__dlm.ssot__LastModifiedDate__c As VARCHAR) UNION SELECT Count(*) AS OccuranceCnt,unifiedindividual__dlm.ssot__id__c AS Id,'MOBILE PHONE' AS ContactPointType,unifiedindividual__dlm.MobilePhone__c AS ContactPoint,individualidentitylink__dlm.ssot__datasourceid__c || ','|| individualidentitylink__dlm.ssot__datasourceobjectid__c || ','|| individualidentitylink__dlm.sourcerecordid__c AS SourceRecord,cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR) As CreatedDate, cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR) As LastModifiedDate FROM unifiedindividual__dlm LEFT JOIN individualidentitylink__dlm ON unifiedindividual__dlm.ssot__id__c = individualidentitylink__dlm.unifiedrecordid__c GROUP BY unifiedindividual__dlm.ssot__id__c,unifiedindividual__dlm.MobilePhone__c,individualidentitylink__dlm.ssot__datasourceid__c || ',' || individualidentitylink__dlm.ssot__datasourceobjectid__c || ',' || individualidentitylink__dlm.sourcerecordid__c, cast(UnifiedIndividual__dlm.ssot__CreatedDate__c As VARCHAR),cast(UnifiedIndividual__dlm.ssot__LastModifiedDate__c As VARCHAR)) WHERE Id IN (SELECT UnifiedRecordId__c FROM IndividualIdentityLink__dlm WHERE ssot__DataSourceId__c = 'Salesforce_00D760000008aLq' AND SourceRecordId__c='0033Z00002ILN4DQAX') ORDER BY Id, ContactPointType\" }";

export default class Oneview extends LightningElement {
    unifiedProfileDetailWrapper;
    isRecordAvailable = false;
    isWaitingForData = false;
    isAdoptButtonDisabled = true;
    isError = false;
    fields = [ID_FIELD, EMAIL_FIELD, PHONE_FIELD, MOBILEPHONE_FIELD, SECONDARYEMAIL_FIELD]
    errorMessage = '';
    @api recordId;
    @api objectApiName;
    CONSTANT = {
        ERROR_STATUS: 'Error',
        ERROR_MESSAGE_1: true,
        ERROR_MESSAGE_2: ' in Customer Data Platfom.',
        SUCCESS_STATUS: 'Success',
        RECORD_UPDATED: 'Record Updated',
        RECORD_NOT_UPDATED: 'Record Not Updated',
        GLOBAL_PARTY_ID_LABEL: 'Unified Profile Id',
        FULL_NAME_LABEL: 'Full Name',
        EMAIL_LABEL: 'Email',
        PHONE_LABEL: 'Phone',
        MOBILE_LABEL: 'Mobile',
        MAILING_LABEL: 'Mailing',
        SYNCADDRESS_FIELD: false,
        CONTACT_POINT_VALUE: 'ContactPointValue'
    };

        @wire(getRecord, {objectApiName: CONTACT_OBJECT })
        contactData;


    @track emailContactPointsList = [];

    connectedCallback() {
        this.isWaitingForData = true;
        getUnifiedProfile({
            recordId: this.recordId
        }).then((result) => {
            this.isWaitingForData = false;
            if (result.status === this.CONSTANT.ERROR_STATUS) {
                this.isRecordAvailable = false;
                this.isError = true;
                this.errorMessage = result.errorMessage;
            } else {
                this.unifiedProfileDetailWrapper = result;
                console.log(
                    'RES:: ',
                    JSON.parse(JSON.stringify(result))
                );
                if (
                    this.unifiedProfileDetailWrapper.UPId ===
                    undefined
                ) {
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
        var radioDeselectElement =
            this.template.querySelectorAll(
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
        return (
            typeof this.doesPartyIdentificationExist ===
            this.unifiedProfileDetailWrapper
                .PartyIdentificationContactPoints
        );
    }
    
    adoptContactDetails() {
        var adoptedEmailValue = '';
        var adoptedPhoneValue = '';
        var adoptedMobileValue = '';
        var adoptedAddressValue = '';
        if (this.selectedEmailIndex !== undefined) {
            adoptedEmailValue = {
                ContactPointValue:
                    this.unifiedProfileDetailWrapper
                        .EmailContactPoints[
                        this.selectedEmailIndex
                    ].contactPointValue
            };
        }
        if (this.selectedPhoneIndex !== undefined) {
            adoptedPhoneValue = {
                ContactPointValue:
                    this.unifiedProfileDetailWrapper
                        .PhoneContactPoints[
                        this.selectedPhoneIndex
                    ].contactPointValue,
                ContactPointType:
                    this.unifiedProfileDetailWrapper
                        .PhoneContactPoints[
                        this.selectedPhoneIndex
                    ].contactPointType
            };
        }
        if (this.selectedMobileIndex !== undefined) {
            adoptedMobileValue = {
                ContactPointValue:
                    this.unifiedProfileDetailWrapper
                        .MobileContactPoints[
                        this.selectedMobileIndex
                    ].contactPointValue,
                ContactPointType:
                    this.unifiedProfileDetailWrapper
                        .MobileContactPoints[
                        this.selectedMobileIndex
                    ].contactPointType
            };
        }
        if (this.selectedAddressIndex !== undefined) {
            adoptedAddressValue = {
                addressLine1:
                    this.unifiedProfileDetailWrapper
                        .AddressContactPoints[
                        this.selectedAddressIndex
                    ].addressLine1,
                cityName:
                    this.unifiedProfileDetailWrapper
                        .AddressContactPoints[
                        this.selectedAddressIndex
                    ].cityName,
                stateProvinceName:
                    this.unifiedProfileDetailWrapper
                        .AddressContactPoints[
                        this.selectedAddressIndex
                    ].stateProvinceName,
                countryName:
                    this.unifiedProfileDetailWrapper
                        .AddressContactPoints[
                        this.selectedAddressIndex
                    ].countryName,
                postalCode:
                    this.unifiedProfileDetailWrapper
                        .AddressContactPoints[
                        this.selectedAddressIndex
                    ].postalCode
            };
        }
        var adoptedValuesJSON = {
            recordID: this.recordId,
            sObjectName: this.objectApiName,
            adoptedEmailValues:
                adoptedEmailValue === ''
                    ? null
                    : adoptedEmailValue,
            adoptedPhoneValues:
                adoptedPhoneValue === ''
                    ? null
                    : adoptedPhoneValue,
            adoptedMobileValues:
                adoptedMobileValue === ''
                    ? null
                    : adoptedMobileValue,
            adoptedAddressValues:
                adoptedAddressValue === ''
                    ? null
                    : adoptedAddressValue
        };
        adoptContactDetails({
            adoptDetailsJSON: JSON.stringify(adoptedValuesJSON)
        }).then((result) => {
            if (result === this.CONSTANT.SUCCESS_STATUS) {
                const evt = new ShowToastEvent({
                    title: this.CONSTANT.SUCCESS_STATUS,
                    message: this.CONSTANT.RECORD_UPDATED,
                    variant: this.CONSTANT.SUCCESS_STATUS
                });
                this.dispatchEvent(evt);
            } else {
                const evt = new ShowToastEvent({
                    title: this.CONSTANT.ERROR_STATUS,
                    message:
                        this.CONSTANT.RECORD_NOT_UPDATED +
                        ' - ' +
                        result,
                    variant: this.CONSTANT.ERROR_STATUS
                });
                this.dispatchEvent(evt);
            }
            this.resetRadioButton();
        });
    }
}