// Author: Flora Lopez

public with sharing class RefactoredOpportunityTriggerHandler extends TriggerHandler {

    // This method will be called when there is a before insert operation
    public override void beforeInsert() {
        List<Opportunity> opps = (List<Opportunity>) Trigger.new;
            OpportunityHelper.setTypeOpportunity(opps);
    
    }
    // This method will be called when there is a before delete operation
    public override void beforeDelete() {
        List<Opportunity> opps = (List<Opportunity>) Trigger.old;
        if(opps != null && !opps.isEmpty()) {
            OpportunityHelper.dontDeleteClosed(opps); // call helper method
        }
    }

    // This method will be called when there is a after insert operation
    public override void afterInsert() {
        List<Opportunity> opps = (List<Opportunity>) Trigger.new;
        if(opps != null && !opps.isEmpty()) {
            OpportunityHelper.createNewTask(opps); // call helper method
            }
        }
 // This method will be called when there is a after update operation
    public override void afterUpdate() {   
        List<Opportunity> opps = (List<Opportunity>) Trigger.new;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        OpportunityHelper.updateOpportunityDescription(opps, oldMap);
    }

// Before Update logic for Opportunity
    public override void beforeUpdate() {
        List<Opportunity> opps = (List<Opportunity>) Trigger.new;
        OpportunityHelper.beforeUpdateQuantityCheck(opps);
    }

// This method will be called when there is an after delete operation 

    public override void afterDelete() {
        List<Opportunity> opps = (List<Opportunity>) Trigger.old;
        OpportunityHelper.sendNotificationOpportunityDeleted(opps);
    }

// After undelete
    public override void afterUndelete() {
        Map<Id, Opportunity> newMap = (Map<Id, Opportunity>) Trigger.newMap;
        List<Opportunity> oppsNew = (List<Opportunity>) Trigger.new;
        OpportunityHelper.assignPrimaryContactAfterUndeleted(newMap);
    }   
}
