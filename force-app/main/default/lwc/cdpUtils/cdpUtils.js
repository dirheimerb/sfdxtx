import { LightningElement } from "lwc";
import { emailRegex, queryParams, phoneRegex, QUERY_API } from "./cdpStrings";

export default class CdpUtils extends LightningElement {
  handleFetch() {
    fetch("http://example.com/" + QUERY_API)
      .then((response) => response.json())
      .then((data) => console.log(data))
      .catch((err) => console.error(err));
  }
}
