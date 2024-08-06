// Author Flora Lopez

public with sharing class AccountTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert() {
        List<Account> accts = (List<Account>) Trigger.new;
        
        AccountHelper.setTypeProspect(accts);
        AccountHelper.addressCopy(accts);
        AccountHelper.setRating(accts);
    }

    public override void afterInsert() {
        List<Account> accts = (List<Account>) Trigger.new;
        AccountHelper.defaultContact(accts);
    }
/*  public static void beforeInsert(List<Account> newAccounts) {
        
    }
   // public AccountTriggerHandler() {

    }
*/
}