@isTest
global class CDP_UnifiedProfileDataMock implements HTTPCalloutMock {
  // Creating a test response
  global HTTPResponse respond(HTTPRequest request) {
    HTTPResponse response = new HTTPResponse();
    // Setting the response body
    response.setBody(
      '{ "data": [ {"OccuranceCnt": 1,"Id": "38ded765-5cff-3182-a24c-9e37991c5dac","ContactPoint": "LOT 120/120A, JALAN GEBENG 2/3\r\nGEBENG INDUSTRIAL ESTATE, PHASE 2 PAHANG DARUL MAKMUR,Kuantan,,26080,MY","ContactPointType": "ADDRESS","SourceRecord": "Salesforce_00D760000008aLq,Contact,0033Z00002NGUPaQAP" },{"OccuranceCnt": 1,"Id": "38ded765-5cff-3182-a24c-9e37991c5dac","ContactPoint": "zzmohd@eastman.com","ContactPointType": "EMAIL","SourceRecord": "Salesforce_00D760000008aLq,Contact,0033Z00002NGUPaQAP"}, { "OccuranceCnt": 1, "Id": "38ded765-5cff-3182-a24c-9e37991c5dac", "ContactPoint": "^,Zulkifli Mohd Yeng", "ContactPointType": "INDIVIDUAL", "SourceRecord": "Salesforce_00D760000008aLq,Contact,0033Z00002NGUPaQAP" },{ "OccuranceCnt": 1,"Id": "38ded765-5cff-3182-a24c-9e37991c5dac", "ContactPoint": "6095856270","ContactPointType": "PHONE","SourceRecord": "Salesforce_00D760000008aLq,Contact,0033Z00002NGUPaQAP"}, {"OccuranceCnt": 1,"Id": "aef714c4-1078-3509-97bc-ee3c298ce628","ContactPoint": "LOT 118 & 119 GEBENG INDUSTRIAL EST\nREGISTRATION NUMBER 319774-X P.O. BOX 12 BALOK PAHANG DARUL MAKMUR,Kuantan,,26080,MY","ContactPointType": "ADDRESS", "SourceRecord": "Salesforce_00D760000008aLq,Contact,003j000001UlbYJAAZ"  }, { "OccuranceCnt": 1,"Id": "aef714c4-1078-3509-97bc-ee3c298ce628", "ContactPoint": "zzmohd@eastman.com", "ContactPointType": "EMAIL", "SourceRecord": "Salesforce_00D760000008aLq,Contact,003j000001UlbYJAAZ" }, {  "OccuranceCnt": 1, "Id": "aef714c4-1078-3509-97bc-ee3c298ce628",            "ContactPoint": "Zulkifli Mohd,Yeng",            "ContactPointType": "INDIVIDUAL",            "SourceRecord": "Salesforce_00D760000008aLq,Contact,003j000001UlbYJAAZ"        },        {            "OccuranceCnt": 1,            "Id": "aef714c4-1078-3509-97bc-ee3c298ce628",            "ContactPoint": "609 5856270",            "ContactPointType": "PHONE",            "SourceRecord": "Salesforce_00D760000008aLq,Contact,003j000001UlbYJAAZ"        }    ],    "startTime": "2021-12-22T05:58:17.031733Z",    "endTime": "2021-12-22T05:58:21.004699Z",    "rowCount": 8,    "queryId": "9467988a-8d17-426c-aaea-cec90b0abbe0",    "done": true,    "metadata": {        "ContactPoint": {            "type": "VARCHAR",            "placeInOrder": 2,            "typeCode": 12        },        "Id": {            "type": "VARCHAR",            "placeInOrder": 1,            "typeCode": 12        },        "OccuranceCnt": {            "type": "BIGINT",            "placeInOrder": 0,            "typeCode": -5        },        "ContactPointType": {            "type": "VARCHAR",            "placeInOrder": 3,            "typeCode": 12        },        "SourceRecord": {            "type": "VARCHAR",            "placeInOrder": 4,            "typeCode": 12        }    }}'
    );
    // Setting the response header
    response.setHeader('Content-Type', 'application/json');
    // Setting the response code
    response.setStatusCode(200);

    // Returning the response
    system.debug('** response ' + response);
    return response;
  }
}
