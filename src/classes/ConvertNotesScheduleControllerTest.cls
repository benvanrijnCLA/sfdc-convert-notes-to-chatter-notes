/**
 * Developed by Doug Ayers (douglascayers.com)
 */
@isTest
private class ConvertNotesScheduleControllerTest {

    @isTest
    static void test_save_new_settings() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        Test.startTest();

        ConvertNotesScheduleController controller = new ConvertNotesScheduleController();

        controller.settings = settings;

        controller.save();

        Test.stopTest();

    }

    @isTest
    static void test_update_existing_settings() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Test.startTest();

        ConvertNotesScheduleController controller = new ConvertNotesScheduleController();

        controller.settings = settings;

        controller.save();

        Test.stopTest();

    }

    @isTest
    static void test_save_error() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Test.startTest();

        ConvertNotesScheduleController controller = new ConvertNotesScheduleController();

        controller.settings = settings;

        delete settings; // will cause error on save because ID field is still populated on controller's reference

        controller.save();

        Test.stopTest();


    }

}
