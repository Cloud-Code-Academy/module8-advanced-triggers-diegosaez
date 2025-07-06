public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    public OpportunityTriggerHandler() {
    }
        override public void beforeUpdate() {
            List<Opportunity> opps = (List<Opportunity>) Trigger.new;
            for(Opportunity opp : opps){
                if(opp.Amount < 5000){
                    opp.addError('Opportunity amount must be greater than 5000');
                }
            }
            
            //Get contacts related to the opportunity account
            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp : opps){
                accountIds.add(opp.AccountId);
            }
            
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

            for (Contact cont : contacts.values()) {
                if (!accountIdToContact.containsKey(cont.AccountId)) {
                    accountIdToContact.put(cont.AccountId, cont);
                }
            }

            for(Opportunity opp : opps){
                if(opp.Primary_Contact__c == null){
                    if (accountIdToContact.containsKey(opp.AccountId)){
                        opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                    }
                }
            }
 
        }

        override public void beforeInsert() {
            List<Opportunity> opps = (List<Opportunity>) Trigger.new;
            for (Opportunity opp : opps) {
                    if (opp.Type == null){
                    opp.Type = 'New Customer';
                    } 
                }

        }

        override public void beforeDelete() {
            List<Opportunity> oldOpps = (List<Opportunity>) Trigger.old;
            for (Opportunity oldOpp : oldOpps){
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        }

        override public void afterInsert() {
            // your logic
            List<Opportunity> opps = (List<Opportunity>) Trigger.new;
            List<Task> newTasks = new List<Task>();
            for (Opportunity opp : opps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                newTasks.add(tsk);
            }
            insert newTasks;
        }

        override public void afterUpdate() {
            // your logic
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Map<Id,Opportunity> idToOpportunity = (Map<Id, Opportunity>)Trigger.oldMap;
            List<Opportunity> opps = (List<Opportunity>) Trigger.new;
            for (Opportunity opp : opps){
                Opportunity oldOpp = idToOpportunity.get(opp.Id);
                if (opp.StageName != null && opp.StageName != oldOpp.StageName) {
                    Opportunity oppToUpdate = new Opportunity();
                    oppToUpdate.Id = opp.Id;
                    oppToUpdate.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                    oppsToUpdate.add(oppToUpdate);
                }               
            }
            update oppsToUpdate;
        }

        override public void afterDelete() {
            // your logic
            List<Opportunity> oldOpps = (List<Opportunity>) Trigger.old;
            notifyOwnersOpportunityDeleted(oldOpps);
        }

        override public void afterUndelete() {
            // your logic
            Map<Id,Opportunity> idToOpportunity = new Map<Id,Opportunity>();
            for (Opportunity opp : (List<Opportunity>) Trigger.new) {
                idToOpportunity.put(opp.Id, opp);
            }
            assignPrimaryContact(idToOpportunity);
        }
    private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : opps){
            if(opp.OwnerId != null){
                ownerIds.add(opp.OwnerId);
            }
        }
        Map<Id, User> ownersById = new Map<Id, User>([SELECT Id, email FROM User WHERE Id IN :ownerIds]);

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            User userEmail = ownersById.get(opp.OwnerId);
            mail.setToAddresses(new String[] { userEmail.Email });
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();
        Map<Id, Opportunity> oppWithoutPrimaryContact = new Map<Id, Opportunity>();
        Set<Id> accounts = new Set<Id>();
        

        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null) {
                oppWithoutPrimaryContact.put(opp.Id, opp);
            }
        }

        for (Opportunity opp : oppWithoutPrimaryContact.values()) {
            if (opp.AccountId != null) {
                accounts.add(opp.AccountId);
            }
        }
        Map<Id, Contact> contactsToInsert = new Map<Id, Contact>();
        for (Contact c : [SELECT Id, AccountId, Title, Name 
                        FROM Contact 
                        WHERE AccountId IN :accounts AND Title = 'VP Sales']) {
            contactsToInsert.put(c.AccountId, c);
        }
        
        for (Opportunity opp : oppWithoutPrimaryContact.values()) {
            if (contactsToInsert.get(opp.AccountId) != null) {
                Opportunity oppToUpdate = new Opportunity();
                oppToUpdate.Id = opp.Id;
                oppToUpdate.Primary_Contact__c = contactsToInsert.get(opp.AccountId).Id;
                oppMapToUpdate.put(opp.Id,oppToUpdate);
            }
            
        }
        update oppMapToUpdate.values();
        
    }
}