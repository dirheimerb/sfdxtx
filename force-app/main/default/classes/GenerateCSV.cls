public class GenerateCSV {
    
    public static GenerateCSV newInstance(){
        return new GenerateCSV();
    }
    //get the opportunity with Products(OpportunityLineItems)
    public OpportunityLineItem[] getOpportunityLineItem(Set<Id> oppIds){
        return [SELECT Id, Opportunity.Id, Opportunity.Name, Opportunity.Owner.Name, Opportunity.Multi_Year_Quote_Pricing_Details__c, Product2Id, Product2.Name, ListPrice, Quantity, UnitPrice 
                FROM OpportunityLineItem
                WHERE OpportunityId IN: oppIds];
    }
    
    public Opportunity[] getApprovedOpportunities(){
        return [SELECT Id
                FROM Opportunity
                WHERE FAB_Price_Exception_Approval_Status__c='Approved'];
    }
    
    //get the opportunity with Quotes (QuoteLineItem)
    public QuoteLineItem[] getQuoteLineItem(Set<Id> oppIds){
        return [SELECT Id, Quote.OpportunityId, UnitPrice, Quantity, Discount, OpportunityLineItemId, 
                QuoteId, Quote.Version__c,Quote.Name, Quote.Status, Description, Product2Id, Product2.Name, ListPrice, Price_Range__c, Quantity_Range__c 
                FROM QuoteLineItem WHERE Quote.OpportunityId IN : oppIds];
    }
    
    public Map<String, QuoteLineItem[]> getQuoteLineItemByProduct2Id(Set<Id> oppIds){
        Map<String, QuoteLineItem[]> qliByProdId = new Map<String, QuoteLineItem[]>();
        for(QuoteLineItem qli: getQuoteLineItem(oppIds)){
            String key = qli.Quote.OpportunityId+'-'+qli.Product2Id;
            QuoteLineItem[] qlis = qliByProdId.get(key);
            if(qlis == null){
                qlis = new QuoteLineItem[0];
                qliByProdId.put(key, qlis);
            }
            qlis.add(qli);
        }
        return qliByProdId;
    }
    
    public void generateCSVFile(Opportunity[] opps){
        opps = opps.isEmpty() ? getApprovedOpportunities() : opps;
        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();
        Map<String, QuoteLineItem[]> qliByProdId = getQuoteLineItemByProduct2Id(oppIds);
            
        //String header ='Opportunity Owner,Opportunity Name,Multi-Year Quote Pricing Details,Quote Name, Item Number,Quantity,List Price,Sales Price';
		
		String header = 'Opportunity Information,,,,,,,Quote Information,,,,,,,,'+'\n';
		header += 'Opportunity name,Opportunity owner,Item Number,Quantity,Sales Price,List Price,,Quote name,Revision,Multi-Year Quote Pricing Details,Product: Item Number,Quantity,Sales Price,List Price,Status,Quantity Range,Price'+'\n';

        String body = header;
        for(OpportunityLineItem oli: getOpportunityLineItem(oppIds)){
            //from oli(porduct)
            body = body+oli.Opportunity.Name.escapeCSV()+','+oli.Opportunity.Owner.Name.escapeCSV()+','+oli.Product2.Name.escapeCSV()+','+oli.Quantity+','+oli.UnitPrice+','+oli.ListPrice+',,';
            
            String key = oli.OpportunityId+'-'+oli.Product2Id;
            //from Quote line Items	
            QuoteLineItem[] qlis = qliByProdId.get(key);
            if(qlis != null){
                //body = body+oli.Opportunity.Name+','+oli.Opportunity.Owner.Name+','+oli.Product2.Name+','+oli.Quantity+','+oli.UnitPrice+','+oli.ListPrice+',,';
				Integer qCount = 0;
                for(QuoteLineItem qli: qlis){
                    //from oli(porduct)
					
					String qRow = '';
                    
					if(qCount>0){
						qRow = ',,,,,,,';
					}
					qRow += qli.Quote.Name.escapeCSV()+','+(string.valueof(qli.Quote.Version__c) != null ? string.valueof(qli.Quote.Version__c).escapeCSV() : '')+','+(oli.Opportunity.Multi_Year_Quote_Pricing_Details__c != null ? oli.Opportunity.Multi_Year_Quote_Pricing_Details__c.stripHtmlTags().escapeCSV() : '')+','+qli.Product2.Name.escapeCSV()+','+qli.Quantity+','+qli.UnitPrice+','+qli.ListPrice+','+qli.Quote.Status.stripHtmlTags().escapeCSV()+','+(qli.Quantity_Range__c!= null ? String.valueOf(qli.Quantity_Range__c).escapeCSV() : '')+','+(qli.Price_Range__c != null ? string.ValueOf(qli.Price_Range__c).escapeCSV(): '')+''+'\n';
					body = body+qRow;
					qCount++;
                }
            } else {
                body = body+',,,,,,,,'+'\n';                
            }
        }        
        
        sendCSV(body);
    }
    
    public void sendCSV(String body){
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(body);
        string csvname= 'Opportunities_with_Products.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[0];
        Opp_FAB_Price_Approved_Report_Config__mdt defaultConfig = Opp_FAB_Price_Approved_Report_Config__mdt.getInstance('Default');
        if(defaultConfig != null && String.isNotBlank(defaultConfig.Email__c)){
            toAddresses = defaultConfig.Email__c.split(';');
        }
        System.debug(toAddresses);
        if(toAddresses.isEMpty()){
            return;
        }
        //String[] toAddresses = new list<string> {'lgutha@wlgore.com'};
        String subject ='Opportunities with Products CSV';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody(subject);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
        
    }
}