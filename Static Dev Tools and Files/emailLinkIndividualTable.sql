INSERT INTO unifiedindividual__dlm VALUES (1, 'Fname1', 'Lname1','abd@abc.com');



INSERT INTO unifiedindividual__dlm VALUES (2, 'Fname2', 'Lname2','abd1@abc.com');



INSERT INTO unifiedindividual__dlm VALUES (3, 'Fname3', 'Lname3','abd2@abc.com');



INSERT INTO unifiedcontactpointemail__dlm values(1);
INSERT INTO unifiedcontactpointemail__dlm values(1);
INSERT INTO unifiedcontactpointemail__dlm values(2);





INSERT INTO contactpointemailidentitylink__dlm values(100,150,1);
INSERT INTO contactpointemailidentitylink__dlm values(200,300,1);
INSERT INTO contactpointemailidentitylink__dlm values(400,500,2);




SELECT DISTINCT ssot__id__c,
ssot__firstname__c,
ssot__lastname__c ,
ssot_email__c,
ssot__partyid__c,
ssot__datasourceid__c,
ssot__datasourceobjectid__c



FROM unifiedindividual__dlm a
INNER JOIN unifiedcontactpointemail__dlm b
ON a.ssot__id__c = b.ssot__partyid__c
INNER JOIN contactpointemailidentitylink__dlm
c
ON a.ssot__id__c = c.unifiedrecordid__c
WHERE a.email__c = 'liseth@tpsavition.com'


SELECT unifiedindividual__dlm.ssot__id__c,
unifiedindividual__dlm.ssot__firstname__c,
unifiedindividual__dlm.ssot__lastname__c ,
unifiedindividual__dlm.email__c,
unifiedcontactpointemail__dlm.ssot__partyid__c,
contactpointemailidentitylink__dlm.ssot__datasourceid__c,
contactpointemailidentitylink__dlm.ssot__datasourceobjectid__c
FROM unifiedindividual__dlm
INNER JOIN unifiedcontactpointemail__dlm
ON unifiedindividual__dlm.ssot__id__c = unifiedcontactpointemail__dlm.ssot__partyid__c
INNER JOIN contactpointemailidentitylink__dlm
ON unifiedindividual__dlm.ssot__id__c = contactpointemailidentitylink__dlm.unifiedrecordid__c
WHERE unifiedindividual__dlm.email__c = ''



{
    "sql": "SELECT unifiedindividual__dlm.ssot__id__c, unifiedindividual__dlm.ssot__firstname__c, unifiedindividual__dlm.ssot__lastname__c, unifiedindividual__dlm.email__c, unifiedcontactpointemail__dlm.ssot__partyid__c, contactpointemailidentitylink__dlm.ssot__datasourceid__c, contactpointemailidentitylink__dlm.ssot__datasourceobjectid__c FROM unifiedindividual__dlm INNER JOIN unifiedcontactpointemail__dlm ON unifiedindividual__dlm.ssot__id__c = unifiedcontactpointemail__dlm.ssot__partyid__c INNER JOIN contactpointemailidentitylink__dlm ON unifiedindividual__dlm.ssot__id__c = contactpointemailidentitylink__dlm.unifiedrecordid__c WHERE unifiedindividual__dlm.email__c = 'liseth@tpsavition.com'"
}