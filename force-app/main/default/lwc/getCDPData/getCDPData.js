import { LightningElement, wire } from 'lwc';
import getCDPToken from '@salesforce/apex/DisplayUnifiedProfileImpl.getCDPToken'
var raw = ''
const host = 'https://gvrg89ddgm2g8yrymjrdsnbrmy.c360a.salesforce.com';

export default class GetCDPData extends LightningElement {

    @wire(getCDPToken)
    Wiredtoken;

    handleResponse(Wiredtoken) {
        var requestOptions = {
            method: 'GET',
            Headers: Wiredtoken,
            body: raw,
            redirect: 'follow'
        };

fetch(host + "/api/v1/profile/UnifiedIndividual__dlm?fields=ssot__Id__c ,ssot__FirstName__c,ssot__LastName__c&limit=5&filters=[Email__c=shop@kitchener.ch]", requestOptions)
    .then(response => response.text())
    .then(result => console.log(result))
    .catch(error => console.log('error', error));

    }
}