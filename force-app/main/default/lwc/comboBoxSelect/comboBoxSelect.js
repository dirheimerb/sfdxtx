import { LightningElement } from "lwc";

export default class ComboBoxSelect extends LightningElement {
  searchOptions = [
    {
      value: "email",
      label: "Email",
    },
    {
      value: "phone",
      label: "Phone",
    },
    {
      value: "mobilePhone",
      label: "Mobile Phone",
    },
  ];

  handleChange(event) {
    this.value = event.detail.value;
  }
  handleKeyUp(evt) {
    const isEnterKey = evt.keyCode === 13;
    if (isEnterKey) {
      this.queryTerm = evt.target.value;
    }
  }
}
