import { LightningElement, api, wire } from "lwc";
import { getRecordUi } from "lightning/uiRecordApi";
import CONTACT_OBJECT from "@salesforce/schema/Contact";

import {
  getObjectInfo,
  getPicklistValuesByRecordType,
} from "lightning/uiObjectInfoApi";

export default class ContactViewForm extends LightningElement {
  objectApiName = CONTACT_OBJECT;

  @api recordId;
  @api recordTypeId;
  @api objectApiName;

  @wire(getObjectInfo, { objectApiNames: CONTACT_OBJECT })
  contactInfo;

  @wire(getRecordUi, {
    recordId: "$recordId",
    layoutTypes: ["full", "compact"],
    modes: ["view", "edit"],
  })
  contactRecordUi;

  @wire(getPicklistValuesByRecordType, {
    objectApiName: CONTACT_OBJECT,
    recordTypeId: "$recordTypeId",
  })
  contactPicklistValues;
}
