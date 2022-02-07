/*
  @description       : 
  @author            : Kalyani Jagdale
  @group             : 
  @last modified on  : 06-01-2021
  @last modified by  : Kalyani Jagdale
  Modifications Log 
  Ver   Date         Author       Modification
  1.0   06-15-2021   Kalyani Jagdale   Initial Version
*/
@isTest
global class CDP_APIUtilsMock implements HTTPCalloutMock {    
  // Creating a test response
  global HTTPResponse respond(HTTPRequest request) {
    HTTPResponse response = new HTTPResponse();
    // Setting the response body
    response.setBody(
      '{"access_token":"eyJraWQiOiJDT1JFLjAwRDVlMDAwMDAxUGpseS4xNjM5OTkyMjEwMDA0IiwidHlwIjoiSldUIiwiYWxnIjoiRVMyNTYifQ.eyJzdWIiOiJodHRwczovL2xvZ2luLnNhbGVzZm9yY2UuY29tL2lkLzAwRDVlMDAwMDAxUGpseUVBQy8wMDU1ZTAwMDAwN0tDN0FBQVciLCJzY3AiOiJjZHBxdWVyeSBjZHBwcm9maWxlIiwiaXNzIjoiaHR0cHM6Ly9sb2dpbi5zYWxlc2ZvcmNlLmNvbS8iLCJvcmdJZCI6IjAwRDVlMDAwMDAxUGpseSIsImlzc3VlclRlbmFudElkIjoiY29yZS9wcm9kLzAwRDVlMDAwMDAxUGpseUVBQyIsInNmYXBwaWQiOiIzTVZHOWNISDJiZktBQ1pibllWRVVfUi5XelB1LkJodHJxZjVHSTJVOFZhWXJjRHpZMzFfTzVYRmxBZGlCZWwxVl9kM21lX3UuZ3c9PSIsImF1ZGllbmNlVGVuYW50SWQiOiJhMzYwL3Byb2QvZTYxZjgzNjhiZjg0NDVjYzhlZDMwYTdiZmQ3ZTgzOTciLCJhdWQiOiJhcGkuYTM2MC5zYWxlc2ZvcmNlLmNvbSIsIm5iZiI6MTY0Mzg5Mjc3MCwic2ZvaWQiOiIwMEQ1ZTAwMDAwMVBqbHkiLCJzZnVpZCI6IjAwNTVlMDAwMDA3S0M3QSIsImV4cCI6MTY0MzkwMDAzMCwiaWF0IjoxNjQzODkyODMwLCJqdGkiOiI4ZGI2YWI5OC00ODFlLTQ5OTAtODI2YS0yM2RkZjZhM2YxNjIifQ.t2iUJUOM0UgIRJVjc1lkb7D08BNH9odZSLa-1EbYi-Cmfe_gH8tS7IrYY20LOjULieiPmiftYpw3vodzN87ZtQ","instance_url":"gvrg89ddgm2g8yrymjrdsnbrmy.c360a.salesforce.com","token_type":"Bearer","issued_token_type":"urn:ietf:params:oauth:token-type:jwt","expires_in":7200}');
    // Setting the response header
    response.setHeader('Content-Type', 'application/json');
    // Setting the response code
    response.setStatusCode(200);

    // Returning the response
    system.debug('** response ' + response);
    return response;
  }
}