/**
 * @description This Class is used to add search methods to flow with salesforce cdp
 * Search will use contacts and leads.
 */

public with sharing class InvocableCDP {
    /**
     * @description Internal exception class
     */
    public class InvocableCDPException extends Exception {
    }
    /**
     * @description Incoming Search Request
     */
    public class CDPSearchRequest {
    @InvocableVariable(
        label='Search CDP - SearchKey'
        description='Search variable'
        required=true
    )
    public List<SObject> searchKey;
    }
    /**
     * @description Value from the invocable method
     */
    public class CDPSearchResults {
        @InvocableVariable(
            label='Search CDP - SearchResponse'
            description='Response Value from SObject'
            required=true
        )
        public SObject searchResponse;
        /**
         * @description Constructor building response from sobject
         * @param toSearchResponse Object to response
         */
        public SearchCDPResponse(SObject toSearchResponse) {
            this.searchResponse = searchResponse;
        }
    }

    /**
     * @description Invocable Method accepts a list of search requests from the CDP 
     * search component.  The first request extracts the input Params to decide which type
     * of search should be done. (Email or Phone)
     * @param searchParams a list of search request objects
     * @return List<CDPSearchResults>
     * @example 
     * From Apex: 
     * 
     */

     @InvocableMethod(
         label='Search CDP Profiles'
         description='Search CDP Database for unified profiles from salescloud or marketing cloud.  These input params will invoke the required methods to complete the search'
     )
     public static List<CdpSearchResult> searchCDP(List<CdpSearchRequest> searchParams
     ) {
         List<SObject> search = inputParams[0].search;
         String firstRequest = search[0]
     }