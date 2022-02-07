import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";

export default class ContactEditForm extends NavigationMixin(LightningElement) {
  showModal = true;
  contactName;
  @api recordId;

  callButton() {
    this.showModal = true;
  }
  closeModal() {
    this.showModal = false;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        objectApiName: "Contact",
        actionName: "view",
      },
    });
    //window.history.back();
  }

  @wire(getRecord, {
    recordId: "$recordId",
    fields: ["Contact.Name"],
  })
  getUserRecord({ data, error }) {
    console.log("data " + data);
    if (data) {
      this.contactName = data.fields.Name.value;
    }
  }
}
