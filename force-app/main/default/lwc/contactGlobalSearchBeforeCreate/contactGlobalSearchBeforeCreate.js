import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

export default class GlobalSearchBeforeCreate extends NavigationMixin(
  LightningElement
) {
  bShowModal = true;
  isSearchButton = true; //to disable search button

  openModal() {
    // to open modal window set 'bShowModal' tarck value as true
    this.bShowModal = true;
  }

  closeModal() {
    // to close modal window set 'bShowModal' tarck value as false  and navigate to contact list view
    this.bShowModal = false;
    console.log("@@@ Test");
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Contact",
        actionName: "list",
      },
      state: {
        filterName: "Recent", // or by 18 char '00BT0000002TONQMA4'
      },
    });
  }
}
