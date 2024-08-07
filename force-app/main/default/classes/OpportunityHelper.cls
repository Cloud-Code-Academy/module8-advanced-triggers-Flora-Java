public with sharing class OpportunityHelper {

    // Set default Type for new Opportunities before insert
    public static void  setTypeOpportunity(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }    
    }
    // Prevent deletion of closed Opportunities before delete
    public static void  dontDeleteClosed(List<Opportunity> opps) {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :opps ) WITH SECURITY_ENFORCED]);
        for(Opportunity opp : opps) {
            if(opp.StageName == 'Closed Won' && accounts.get(opp.AccountId).Industry == 'Banking') {
                opp.addError('Cannot delete closed opportunity');
                continue;
            }
            if (opp.StageName == 'Closed Won') {
                opp.addError('Cannot delete closed opportunity');
                continue;
            }
            if (opp.StageName == 'Closed Lost') {
                opp.addError('Cannot delete closed opportunity');
                continue;
            }
        }
    }

    // Create a new Task for newly inserted Opportunities, after insert
    public static void  createNewTask(List<Opportunity> opps) {
        List<Task> tasks = new List<Task>();
        for (Opportunity opp : opps) {
            Task tsk = new Task(
                Subject = 'Call Primary Contact',
                WhatId = opp.Id,
                OwnerId = opp.OwnerId,
                WhoId = opp.Primary_Contact__c,
                ActivityDate = Date.today().addDays(3)
            );
            tasks.add(tsk);
        }
    // Divide the task list into chunks of 150  and calulate the total number of batches
    Integer batchSize = 150;
    Integer totalTasks = tasks.size();
    Integer batches = (totalTasks + batchsize -1)/ batchSize;

    for (Integer x = 0; x < batches; x++) {
        // Create a new list of Task for batch processing
        List<Task> batch = new List<Task>();

        // calculate indexes start and end
        Integer start = x * batchSize;
        Integer end1 = Math.min(start + batchSize, totalTasks);
        // create sublist 
        for (Integer j = start; j < end1; j++) {
            batch.add(tasks[j]);
        }
        // insert the sublist into the database
        Database.insert(batch, false);    
        }
    }

    //Check amount to be > 5000 before update
    public static void beforeUpdateQuantityCheck(List<Opportunity> opps) {
        for(Opportunity opp : opps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }

        //adding a primary contact with title CEO
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
            if (accountIdToContact.containsKey(opp.AccountId)) {
                Contact ceoContact = accountIdToContact.get(opp.AccountId);
                opp.Primary_Contact__c = ceoContact.Id; 
            }
        }
    }

    //Append stage changes to Opp description after update
    public static void updateOpportunityDescription(List<Opportunity> opps, Map<Id, Opportunity> oldMap)  {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName != oldOpp.StageName){
                oppsToUpdate.add( new Opportunity(
                    Id = opp.Id,
                    Name = opp.Name,
                    StageName= opp.StageName,
                    Description = 'Stage Change:' + opp.StageName + ':' + DateTime.now().format()
                ));
            }
        }
        update as user oppsToUpdate;
        
    }

    // send notification when opportunity is deleted
    public static void sendNotificationOpportunityDeleted(List<Opportunity> deletedOpps) {
        notifyOwnersOpportunityDeleted(deletedOpps);
    }
    // Assign the primary contact to undeleted Opportunities after undelete
    public static void assignPrimaryContactAfterUndeleted(Map<Id,Opportunity> opps) {
        assignPrimaryContact(opps, 'VP Sales');
    }

    // method to send the notification
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        //get id's from Opp owners
        Set<Id> userIds = new Set<Id>();
        for (Opportunity opp : opps) {
            userIds.add(opp.OwnerId);
        }
        // get emails
        List<User> queriedUsers = [SELECT Id, Email FROM User WHERE Id IN :userIds WITH SECURITY_ENFORCED];
        
        Map<Id, String> userEmails = new Map<Id, String>();
        for (User usr : queriedUsers) {
            userEmails.put(usr.Id, usr.Email);
        }
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddress = new List<String>();
            String ownerEmail = userEmails.get(opp.OwnerId);
            toAddress.add(ownerEmail);
            mail.setToAddresses(toAddress);
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
    // assign primary contact
    public static void assignPrimaryContact(Map<Id,Opportunity> opps, String contactTitle ) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps.values()) {
            accountIds.add(opp.AccountId);
        }
        List<Contact> allContacts = new List<Contact>(
            [SELECT Id, AccountId FROM Contact WHERE Title = :contactTitle AND AccountId = :accountIds WITH SECURITY_ENFORCED]
        );
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        for (Contact con : allContacts) {
            contactMap.put(con.AccountId, con);
        }
            
        Map<Id, Opportunity> oppMapToUpdate = new Map<Id, Opportunity>();

        for (Opportunity opp : opps.values()) {
            if(opp.Primary_Contact__c == null) {
                Contact primaryContact = new Contact();
                primaryContact = contactMap.get(opp.AccountId);
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = primaryContact.Id;
                oppMapToUpdate.put(opp.Id, oppToUpdate);
                
            }
        }
        if(oppMapToUpdate.size() > 0) {
            update as user oppMapToUpdate.values();
        }
    }
}