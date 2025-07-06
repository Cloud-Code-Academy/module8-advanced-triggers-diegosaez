trigger OpportunityTrigger on Opportunity (before update, after insert, after update, after delete, before delete, before insert, after undelete) {
    new OpportunityTriggerHandler().run();
}