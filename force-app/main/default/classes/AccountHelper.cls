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

Remember:
Always ensure that your helper methods are bulk-safe to handle multiple records efficiently. 
*/
public with sharing class AccountHelper {
    
    public static void setTypeProspect(List<Account> accountList){
        for (Account acc : accountList) {
            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }
        }
    }

    public static void addressCopy(List<Account> accountList){
        for (Account acc : accountList) {
            if (acc.ShippingStreet != null) {
                acc.BillingStreet = acc.ShippingStreet;
            }

            if (acc.ShippingCity != null) {
                acc.BillingCity = acc.ShippingCity;
            }

            if (acc.ShippingState != null) {
                acc.BillingState = acc.ShippingState;
            }

            if (acc.ShippingPostalCode != null) {
                acc.BillingPostalCode = acc.ShippingPostalCode;
            }

            if (acc.ShippingCountry != null) {
                acc.BillingCountry = acc.ShippingCountry;
            }
        }   
    }

    //[public | private ] [static] data_type setRating (input parameters) {
    //  The body of the method
    //}
    public static void setRating(List<Account> accountList) {
        for (Account acc : accountList) {
            if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
                acc.Rating = 'Hot';
            }
        }
    }
    //[public | private ] [static] data_type defaultContact (input parameters) {
    //  The body of the method
    //}
    public static void defaultContact (List<Account> accountList) {
        List<Contact> contacts = new List<Contact>();   
        for(Account acc : accountList){
            Contact con = new Contact();
            con.LastName = 'DefaultContact';
            con.Email = 'default@email.com';
            con.AccountId = acc.Id;
            contacts.add(con);
        }
        insert contacts; 
    }
}
 