/**
 * Developed by Doug Ayers (douglascayers.com)
 */
@isTest
private class ConvertNotesRunOnceControllerTest {

    @isTest
    static void test_convert_all() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Account acct1 = new Account(
            name = 'Test Account 1'
        );

        insert acct1;

        Account acct2 = new Account(
            name = 'Test Account 2'
        );

        insert acct2;

        Note note1 = new Note(
            title = 'Hello World 1.txt',
            body = 'Hello World 1',
            parentId = acct1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2.txt',
            body = 'Hello World 2',
            parentId = acct2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesRunOnceController controller = new ConvertNotesRunOnceController();

        controller.submitJob();

        Test.stopTest();


    }

    @isTest
    static void test_convert_one() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Account acct1 = new Account(
            name = 'Test Account 1'
        );

        insert acct1;

        Account acct2 = new Account(
            name = 'Test Account 2'
        );

        insert acct2;

        Note note1 = new Note(
            title = 'Hello World 1.txt',
            body = 'Hello World 1',
            parentId = acct1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2.txt',
            body = 'Hello World 2',
            parentId = acct2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesRunOnceController controller = new ConvertNotesRunOnceController();
        controller.parentIdsCsv = acct1.id + ',' + acct1.id; // same id, comma separated to test split

        controller.submitJob();

        Test.stopTest();

    }

    @isTest
    static void test_convert_error() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Account acct1 = new Account(
            name = 'Test Account 1'
        );

        insert acct1;

        Account acct2 = new Account(
            name = 'Test Account 2'
        );

        insert acct2;

        Note note1 = new Note(
            title = 'Hello World 1.txt',
            body = 'Hello World 1',
            parentId = acct1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2.txt',
            body = 'Hello World 2',
            parentId = acct2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesRunOnceController controller = new ConvertNotesRunOnceController();
        controller.batchSize = -10; // negative, should cause error

        controller.submitJob();

        Test.stopTest();

    }

}
