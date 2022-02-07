/**
 * Implementation class for Jira. This class can be customized including extra logic, and cloned for supporting another provider.
 *
 * How to schedule the fetch process:
 * ScheduleUserStoryFetch Susf = new ScheduleUserStoryFetch (prpjectRecordId);
 * String str = Datetime.now().addSeconds(5).format('s m H d M ? yyyy');
 * String jobID = system.schedule('ScheduleUserStoryFetch - ' + DateTime.Now() + '.' + math.mod(DateTime.now().getTime(), 1000), str, Susf);
 * @author Ümit Can Uçkan
 * @version 1.11
 */

public with sharing class JiraIntegration implements IIntegration {
    
    //CONSTANTS
    //string
    private final String EMPTY_CHAR = '';
    private final String ONE_CHAR = ' ';
    private final String COMMA = ',';
    private final String STATUS = 'status';
    private final String FIELDS_STRING = 'fields';
    private final String PROJECTID = 'projectid';
    private final String ASSIGNEE = 'assignee';
    private final String DEVELOPER = 'developer';
    private final String ID_STRING = 'id';
    private final String KEY_STRING = 'key';
    private final String INTEGER_STRING = 'integer';
    private final String OBJECT_STRING = 'object';
    private final String TOTAL_STRING = 'total';
    private final String START_AT = 'startAt';
    private final String START_AT_URI = '&startAt=';
    private final String ISSUES_STRING = 'issues';
    private final String EMAIL_ADDRESS = 'emailAddress';
    private final String ENCODING_TYPE = 'UTF-8';

    //integer 
    private final Integer PAGINATION_SIZE = 50;
    //field apis
    private final String COPADO_STATUS = 'copado__Status__c';
    private final String EXTERNAL_ID = 'External_Id__c';
    private final String ENABLE_LOGS = 'Enable_Logs__c';
    private final String NAME = 'name';
    
    //endpoint path to fetch records from Jira
    private final String AUTH_QUERY_PATH = 'search?jql=project=';

    //headers for callout
    private final String CONTENT_TYPE_HEADER = 'Content-Type:application/json';
    private final String CONNECTION_HEADER = 'Connection:keep-alive';

    //Json template to use on String.format function for Object types
    private final String JSON_TEMPLATE_INNER_OBJECT = '"{0}" :lcurly"name" : "{1}"rcurly';
    //Json template to use on String.format function for String types
    private final String JSON_TEMPLATE_INNER_STRING = '"{0}" :"{1}"';
    //Json template to use on String.format function for Integer types
    private final String JSON_TEMPLATE_INNER_INTEGER = '"{0}" :{1}';
    private final String JSON_TEMPLATE_OUTER = '{"fields" : {';
    private final String JSON_TEMPLATE_OUTER_CLOSURE = '}}';

    private final String DONT_EXCLUDE_FROM_THIRD_PARTY = ' and Exclude_from_tpu__c = false';

     //template to be able to change the status via transition
    //in use on updateStatus method
    private final String transitionTemplate = 'lcurly"transition":lcurly"id":"{0}"rcurlyrcurly';

    //endpoint path to reach to specified issue
    private final String updateParameterString = 'issue/{0}';
    //endpoint path to fetch available statuses on related issue
    private final String updateParameter4TransitionString = 'issue/{0}/transitions?Expand=transitions.fields';
    
    //NON-CONSTANTS
    //will be filled with related project/user Story record
    public String projectExtId;
    public String namedCredential;
    public String jqlExtFilter {
        get{
            if(String.isBlank(jqlExtFilter)){
                jqlExtFilter = '';
            }
            return jqlExtFilter;
        }
        private set;
    }
    
    //current copado__project__c record id
    public Id pId;

    //List of Map collector to be able to return records from json response to batch class
    public List<Map<String,String>> userStoryList {
        get {
            if(null == userStoryList){
                userStoryList = new List<Map<String,String>>();
            }
            return userStoryList;
        }
        set;
    }

    //salesforce field api to third party field Mapping to use on third party record update operation
    public Map<String,String> fieldMap {
        get {
            if(null == fieldMap){
                fieldMap = CopadoCCMutilities.returnFieldMap(pId, DONT_EXCLUDE_FROM_THIRD_PARTY);
            }
            return fieldMap;
        }
        set;
    }
    
    public String fieldsToFetch { 
        get {
            if(String.isBlank(fieldsToFetch)){
                Map<String,String> sfFieldMap = new Map<String,String>();
                for(Field_Mapping__c fm : database.query('SELECT Salesforce_Field_Name__c, Third_Party_Field_Name__c FROM Field_Mapping__c WHERE project__c =: pid and Exclude_from_su__c = false')){
                    sfFieldMap.put(fm.Salesforce_Field_Name__c.toLowerCase(),fm.Third_Party_Field_Name__c/*.toLowerCase()*/);
                }
                fieldsToFetch = String.join(sfFieldMap.values(),  COMMA) + COMMA + ASSIGNEE  + COMMA + ID_STRING + COMMA + KEY_STRING + COMMA + PROJECTID;
            }
            return fieldsToFetch;
        }
        set;
    }

    //salesforce field api to third party field type Mapping to use on third party record update operation
    //exps: copado__status__c => Object
    public Map<String,String> typeMap {
        get{
            if(null == typeMap){
                typeMap = CopadoCCMutilities.returnTargetTypeMap(pId, DONT_EXCLUDE_FROM_THIRD_PARTY);
            }
            return typeMap;
        }
        set;
    }

    //String comma seperated queries to us on sObject record query on updateRecord method
    public String queryFields {
        get {
            if(String.isBlank(queryFields)){
                queryFields = String.join(new List<String>(fieldMap.keyset()), COMMA);
                if(!queryFields.contains(EXTERNAL_ID)){
                    queryFields += COMMA + EXTERNAL_ID;
                }
                if(!queryFields.contains(ENABLE_LOGS)){
                    queryFields += COMMA + ENABLE_LOGS;
                }
            }
            return queryFields;
        }
        set;
    }
    
    //Record type map to map jira issue type with Copado record types
    public Map<String, String> recordTypeMap {
        get {
            if(null == recordTypeMap){
                recordTypeMap = new Map<String, String>();
                List<RecordType> userStoryRecordTypes = [SELECT Id, Name, DeveloperName 
                                                         FROM RecordType 
                                                         WHERE SobjectType = 'copado__User_Story__c' AND IsActive = True];
                for(RecordType rt : userStoryRecordTypes) {
                    recordTypeMap.put(rt.Name != 'User Story' ? rt.Name : 'Story', rt.Id);
                }
                /*recordTypeMap.put('bug', Schema.SobjectType.copado__User_Story__c.getRecordTypeInfosByName().get('Bug').getRecordTypeId());
                recordTypeMap.put('story', Schema.SobjectType.copado__User_Story__c.getRecordTypeInfosByName().get('User Story').getRecordTypeId());*/
            }
            return recordTypeMap;
        }
        set;
    }
    
    public Map<String, copado__Sprint__c> sprints;
    public Map<String, copado__Release__c> releases;

    //INTEGRATION CORE METHODS 
    /**
     * Updates single record based on external Id on Jira.
     * This method will be triggered by the SendUpdatedValues2TP Process Builder Flow on User Story change criteria (customizable in the flow).
     *
     * @param usItem
     */
    public void updateRecord(copado__User_Story__c usItem){
        pId = usItem.copado__Project__c;
        projectExtId = usItem.copado__Project__r.Project_External_Id__c;
        namedCredential = usItem.copado__Project__r.Copado_Integration_Setting__r.Named_Credential__c;
        Id usId = usItem.Id;
        sObject cUserStory = database.query('SELECT ' + queryFields + ' FROM copado__User_Story__c WHERE Id=:usId');
        String finalJson = JSON_TEMPLATE_OUTER;
        for(String s : fieldMap.keyset()){
            if(null != cUserStory.get(s) && fieldMap.get(s) != STATUS){
                finalJson += String.format(
                    (typeMap.get(s) == OBJECT_STRING ? JSON_TEMPLATE_INNER_OBJECT : (typeMap.get(s) == INTEGER_STRING ? JSON_TEMPLATE_INNER_INTEGER : JSON_TEMPLATE_INNER_STRING)), 
                    new List<String>{
                        fieldMap.get(s),
                        String.escapeSingleQuotes(String.valueOf(cUserStory.get(s)))
                    }
                ) + COMMA;
            }
        }
        //callout body to update Jira record which is created from field mappings under related project and current field values
        finalJson = CopadoCCMutilities.replaceFromCurly(finalJson.substring(0,finalJson.length()-1) + JSON_TEMPLATE_OUTER_CLOSURE);
        String responseText = CopadoCCMutilities.MakeCallout(
            namedCredential,
            EMPTY_CHAR, 
            EMPTY_CHAR, 
            String.format(
                updateParameter4TransitionString,
                new List<String>{
                    (String)cUserStory.get(EXTERNAL_ID)
                }
            ),
            EMPTY_CHAR,
            new List<String>{
                CONTENT_TYPE_HEADER
            },
            Method.GET,
            null,
            cUserStory,
            null
        );
        //Jira status update on a different method, since status is a state, not a field on Jira
        updateStatus(responseText,cUserStory);

        //callout for field update
        String responseTextFields = CopadoCCMutilities.MakeCallout(namedCredential, EMPTY_CHAR, EMPTY_CHAR, String.format(updateParameterString, new List<String>{(String)cUserStory.get(EXTERNAL_ID)}),'',new List<String>{CONTENT_TYPE_HEADER},Method.PUT,finalJson,cUserStory,null);
        CopadoCCMutilities.createLogRecords();
    }

    /**
     * Fetches records from Jira in JSON format
     *
     * @param selectedProject
     *
     * @return List<Map<String,String>>
     */
    public List<Map<String,String>> fetchRecords(copado__Project__c selectedProject){
        sprints = new Map<String, copado__Sprint__c>();
        releases = new Map<String, copado__Release__c>();
        pid = selectedProject.id;
        projectExtId = null != selectedProject.Project_External_Id__c ? selectedProject.Project_External_Id__c : EMPTY_CHAR;
        namedCredential = selectedProject.Copado_Integration_Setting__r.Named_Credential__c;

        correctExtendedFilter(selectedProject.JQL_Extended_Filter__c);

        Integer startIndex = 0;
        Boolean shouldContinue = true;
        Integer total;
        //System.debug('fieldsToFetch:: ' + fieldsToFetch);
        
        //Gets issues via JQR
        while(shouldContinue) {
            String responseText = CopadoCCMutilities.MakeCallout(
                namedCredential,
                EMPTY_CHAR, 
                projectExtId+jqlExtFilter, 
                AUTH_QUERY_PATH, 
                START_AT_URI + startIndex + '&fields='+fieldsToFetch, 
                new List<String>{
                    CONTENT_TYPE_HEADER
                }, 
                Method.GET, 
                null, 
                null, 
                selectedProject
            );
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(responseText);
            //Pagination variables, Jira fetch is limited to 50 records by default
            total = Integer.valueOf(results.get(TOTAL_STRING));
            startIndex = Integer.valueOf(results.get(START_AT));
            List<Object> issues = (List<Object>) results.get(ISSUES_STRING);
            
            if(null == issues){
                return new List<Map<String,String>>();
            }
            
            iterateThroughIssues(issues);
            if(total - startIndex < PAGINATION_SIZE){
                shouldContinue = false;
            } else {
                startIndex = startIndex + PAGINATION_SIZE;
            }
        }
        CopadoCCMutilities.createLogRecords();
        Database.upsert(sprints.values(), copado__Sprint__c.fields.Jira_External_Id__c);
        Database.upsert(releases.values(), copado__Release__c.fields.Jira_External_Id__c);
        //Returns list to executeUserStoryUpsert batch class
        return this.userStoryList;
    }

    /**
     * Updates Jira fields
     *
     * @param responseText
     * @param cUserStory
     */
    public void updateStatus(String responseText, sObject cUserStory){
        String statusfinalJson = EMPTY_CHAR;
        //System.debug(responseText);
        JSONParser parser = JSON.createParser(responseText);
        //Wrapper class direct parse
        TransitionWrapper transitionWrapperItem = (TransitionWrapper)parser.readValueAs(TransitionWrapper.class);
        String currentStatusValue = (String)cUserStory.get(COPADO_STATUS);
        Boolean calloutFlag = false;
        for(Transitions tw:transitionWrapperItem.Transitions){
            //Checks if the current status is available on Jira workflow, if not, does not do the callout
            //System.debug(tw);
            /*if(tw.name.toLowerCase() == currentStatusValue.toLowerCase()){
                statusfinalJson = CopadoCCMutilities.replaceFromCurly(String.format(transitionTemplate,new List<String>{tw.id}));
                calloutFlag = true;
                break;
            }  */
            if(tw.to != null){
                //check value in to
                    if(tw.to.name.toLowerCase() == currentStatusValue.toLowerCase()){
                        statusfinalJson = CopadoCCMutilities.replaceFromCurly(String.format(transitionTemplate, new List<String>{tw.id}));
                        calloutFlag = true;
                        break;
                    }
            } else {
                if(tw.name.toLowerCase() == currentStatusValue.toLowerCase()){
                    statusfinalJson = CopadoCCMutilities.replaceFromCurly(String.format(transitionTemplate, new List<String>{tw.id}));
                    calloutFlag = true;
                    break;
                }
            }

        }
        //System.debug(calloutFlag + ' ' + statusfinalJson);
        if(calloutFlag) {
            CopadoCCMutilities.MakeCallout(
                namedCredential,
                EMPTY_CHAR, 
                EMPTY_CHAR, 
                String.format(
                    updateParameter4TransitionString,
                    new List<String>{
                        (String)cUserStory.get(EXTERNAL_ID)
                    }
                ),
                EMPTY_CHAR,
                new List<String>{
                    CONTENT_TYPE_HEADER
                },
                Method.POST,
                statusfinalJson,
                cUserStory,
                null
            );
        }
    }
    //INTEGRATION HELPER METHODS
    private void iterateThroughIssues(List<Object> issues){
        Map<String, String> keyValuepairTempMap;
        
        for (Object issue : issues) {
            keyValuepairTempMap = new Map<String, String>();
            Map<String, Object> currentIssue = (Map<String, Object>) issue;
            //Below three rows are in use for look up and external id purpose
            keyValuepairTempMap.put(KEY_STRING, (String) currentIssue.get(KEY_STRING));
            keyValuepairTempMap.put(ID_STRING, (String) currentIssue.get(ID_STRING));
            keyValuepairTempMap.put(PROJECTID, pid);
            if (null != currentIssue.get(FIELDS_STRING)) {
                Map<String, Object> fields = (Map<String, Object>) currentIssue.get(FIELDS_STRING);
                for (String cf : fields.keySet()) {
                    //Prepares values from String
                    if (fields.get(cf) instanceof String || fields.get(cf) instanceof Integer || fields.get(cf) instanceof Decimal || fields.get(cf) instanceof Double || fields.get(cf) == null) {
                        keyValuepairTempMap.put(cf, String.valueOf(fields.get(cf)));
                    }
                    //Prepares values from Json Object
                    else if (fields.get(cf) instanceof Map<String, Object>) {
                        Map<String, Object> tempObject = (Map<String, Object>) fields.get(cf);
                        //system.debug('************* tempObject: fields get(cf) '+tempObject);
                        if(cf == 'issuetype'){
                            String recTypeId = recordTypeMap.get(String.valueOf(tempObject.get('name')));
                            if(String.isNotBlank(recTypeId)) {
                                keyValuepairTempMap.put('issuetype', recordTypeMap.get(String.valueOf(tempObject.get('name'))));
                            }
                        } else if (null != tempObject.get(EMAIL_ADDRESS)) {
                            //Fills up user look up fields, if email address in use on Third Party Platform matches any of the email addresses on current salesforce org.
                            String cuEmail = (String) tempObject.get(EMAIL_ADDRESS);
                            if (cf == ASSIGNEE && CopadoCCMutilities.userMap.containsKey(cuEmail)) {
                                keyValuepairTempMap.put(DEVELOPER, CopadoCCMutilities.userMap.get(cuEmail));
                            } else keyValuepairTempMap.put(cf, (String) tempObject.get(EMAIL_ADDRESS));
                        } else if (null != tempObject.get(NAME)) {
                            keyValuepairTempMap.put(cf, (String) tempObject.get(NAME));
                        }
                    } else if(fields.get(cf) instanceof List<Object>){ //Jira array type
                    //system.debug('********** before  if sprint' );
                    
                        if(cf == 'customfield_10022' && fields.get(cf) != null){ //sprint field custom key
                        //system.debug('********** inside  if sprint' );
                            List<Object> tempObject = (List<Object>) fields.get(cf);
                            Map<String, Object> tempResult = (Map<String, Object>)tempObject[0];
                            Integer extId = Integer.valueOf(tempResult.get('id'));
                            copado__Sprint__c upsertSprint = new copado__Sprint__c(Jira_External_Id__c = String.valueOf(extId), Name = (String)tempResult.get('name'), copado__Project__c = pId);
                            //system.debug('**********sprint: '+upsertSprint );
                            sprints.put(String.valueOf(extId), upsertSprint);
                            keyValuepairTempMap.put(cf, String.valueOf(extId));
                            
                        } else if(cf == 'fixVersions'){ 
                        //system.debug('********** inside  if fixVersions' );
                            List<Object> tempObject = (List<Object>) fields.get(cf);
                            if(tempObject.isEmpty()){
                                continue;
                            }
                            Map<String, Object> result = (Map<String, Object>) tempObject[0];
                            String extId = (String) result.get('id');
                            String extName = (String) result.get('name');
                            copado__Release__c upsertRelease = new copado__Release__c(Jira_External_Id__c = extId, Name = extName, copado__Project__c = pId);
                            //system.debug('**********fixVersion: '+ upsertRelease );
                            keyValuepairTempMap.put(cf.toLowerCase(), extId);
                            releases.put(extId, upsertRelease);
                        } 
                    }
                }
                userStoryList.add(keyValuepairTempMap);
            }
        }
    }

    private void correctExtendedFilter(String jqlFilter){
        if(String.isNotBlank(jqlFilter)){
            if(jqlFilter.length() >= 3) {
                if (jqlFilter.toLowercase().replace(ONE_CHAR, EMPTY_CHAR).substring(0, 3) != 'and'){
                    jqlExtFilter = projectExtId.length() > 0 ? ' AND ' : EMPTY_CHAR;
                }
                jqlExtFilter += jqlFilter;
                jqlExtFilter = EncodingUtil.urlEncode(jqlExtFilter, ENCODING_TYPE);
            }
        }
    }
    
    /**
     * Wrapper classes for direct casting of Transition Callout response
     */
    public class TransitionWrapper {
        public List<Transitions> Transitions;
    }
    public class Transitions {
        public String id;
        public String name; 
        public InnerTransition to; 
    }
    public class InnerTransition {
        public String id;
        public String name;
    }

}