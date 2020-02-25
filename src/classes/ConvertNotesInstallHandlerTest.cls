/**
 * Developed by Doug Ayers (douglascayers.com)
 */
@isTest
private class ConvertNotesInstallHandlerTest {

    @isTest
    static void test_new_install() {

        Test.startTest();

        Test.testInstall( new ConvertNotesInstallHandler(), null );

        Test.stopTest();

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();


    }

    @isTest
    static void test_upgrade() {

        Convert_Notes_to_ContentNotes_Settings__c preSettings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        preSettings.Convert_in_Near_Real_Time__c = true;
        preSettings.Delete_Note_Once_Converted__c = true;

        upsert preSettings;

        Test.startTest();

        Test.testInstall( new ConvertNotesInstallHandler(), new Version( 1, 0 ) );

        Test.stopTest();

        Convert_Notes_to_ContentNotes_Settings__c postSettings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();


    }

}
