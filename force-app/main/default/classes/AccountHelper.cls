/*
AccountHelper Overview

The `AccountHelper` class is designed to provide helper methods that assist in performing specific operations on Account records. 
This class is intended to modularize the logic used in the `AccountTrigger` to ensure separation of concerns, improve readability, and ease maintenance. 

This class is currently stubbed out. As part of this exercise, you are expected to:
1. Implement the method bodies to carry out the specified operations on Account records.
2. Refactor the `AccountTrigger` to utilize the methods provided in this `AccountHelper` class.

Methods:
- `setTypeProspect(SObject objects)`: 
    - Purpose: Update the 'Type' field of the given Account record to 'Prospect' if it's not already set.
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `addressCopy()`: 
    - Purpose: Copy the shipping address of the Account to its billing address. 
    - Note: You'll likely need to adjust the method signature to accept the necessary parameters.

- `setRating`: 
    - Purpose: Evaluate certain conditions on the Account and assign a rating based on that evaluation. You'll need to define the method's signature and implement its logic.

- `defaultContact`: 
    - Purpose: Create a default contact related to the Account after the Account is inserted. You'll need to define the method's signature and implement its logic.
    
    Author: Flora Lopez
    
Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper {

    public static void  setTypeProspect(List<Account> accts){
    
        for(Account acct : accts){
            if (acct.Type == null) {
                acct.Type = 'Prospect';
            }
        }          
    }

    public static void addressCopy(List<Account> accts){
        for (Account acct : accts) {
            if(!String.isBlank(acct.ShippingStreet) &&
            !String.isBlank(acct.ShippingCity) &&
            !String.isBlank(acct.ShippingState) &&
            !String.isBlank(acct.ShippingPostalCode) &&
            !String.isBlank(acct.ShippingCountry)) {
                acct.BillingStreet = acct.ShippingStreet;
                acct.BillingCity = acct.ShippingCity;
                acct.BillingState = acct.ShippingState;
                acct.BillingPostalCode = acct.ShippingPostalCode;
                acct.BillingCountry = acct.ShippingCountry;  
            }
        }
    }

    public static void setRating(List<Account> accnts) {
        for (Account acct : accnts) {
            if (!String.isBlank(acct.Phone) &&
            !String.isBlank(acct.Website) &&
            !String.isBlank(acct.Fax)){
                acct.Rating = 'Hot';
            }
        }
    }
    
    public static void defaultContact(List<Account> accnts) {
        List<Contact> contacts = new List<Contact>();
        for (Account accnt : accnts) {
            contacts.add(new Contact(
                AccountId = accnt.Id,
                LastName = 'DefaultContact',
                Email = 'default@email.com'));
        }
        if (contacts.size() !=0) {
            insert as user contacts;
        }
    }

}
