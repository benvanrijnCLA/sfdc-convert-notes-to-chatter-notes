/**
 * Developed by Doug Ayers (douglascayers.com)
 */
@isTest
private class ConvertNotesToContentNotesBatchableTest {

    @isTest
    static void test_real_time_trigger() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = true;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account acct1 = new Account(
            name = 'Test Account',
            ownerId = user1.id
        );

        insert acct1;

        Note note1 = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = acct1.id,
            ownerId = user1.id
        );

        Test.startTest();

        System.runAs( user1 ) {

            insert note1;

        }

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

        ContentDocumentLink cdl_note1 = [
            SELECT
                id,
                contentDocumentId,
                contentDocument.latestPublishedVersion.original_record_id__c,
                contentDocument.latestPublishedVersion.original_record_parent_id__c,
                contentDocument.latestPublishedVersion.original_record_owner_id__c
            FROM
                ContentDocumentLink
            WHERE
                linkedEntityId = :acct1.id
                AND
                contentDocument.latestPublishedVersion.original_record_id__c = :note1.id
        ];

    }

    @isTest
    static void test_scope_conversion() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account acct1 = new Account(
            ownerId = user1.id,
            name = 'Test Account 1'
        );

        insert acct1;

        Account acct2 = new Account(
            ownerId = user2.id,
            name = 'Test Account 2'
        );

        insert acct2;

        Note note1 = new Note(
            title = 'Hello World 1.txt',
            body = 'Goodnight Moon',
            parentId = acct1.id,
            ownerId = user1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2.txt',
            body = 'Goodnight Moon 2',
            parentId = acct2.id,
            ownerId = user2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions( settings );
        options.parentIds = new Set<ID>{ acct1.id };

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable( options );

        Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

        ContentDocumentLink cdl_note1 = [
            SELECT
                id,
                contentDocumentId,
                contentDocument.latestPublishedVersion.original_record_id__c,
                contentDocument.latestPublishedVersion.original_record_parent_id__c,
                contentDocument.latestPublishedVersion.original_record_owner_id__c
            FROM
                ContentDocumentLink
            WHERE
                linkedEntityId = :acct1.id
                AND
                contentDocument.latestPublishedVersion.original_record_id__c = :note1.id
        ];

    }

    @isTest
    static void test_preserve_original_owner() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account acct = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert acct;

        Note note1 = new Note(
            title = 'Hello World 1.txt',
            body = 'Goodnight Moon',
            parentId = acct.id,
            ownerId = user1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2.txt',
            body = 'Goodnight Moon 2',
            parentId = acct.id,
            ownerId = user2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable();

        Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }



    }

    @isTest
    static void test_preserve_original_inactive_owner() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account acct = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert acct;

        System.runAs( user1 ) {

            Note note1 = new Note(
                title = 'Hello World 1.txt',
                body = 'Goodnight Moon',
                parentId = acct.id,
                ownerId = user1.id
            );

            insert note1;

        }

        System.runAs( user2 ) {

            Note note2 = new Note(
                title = 'Hello World 2.txt',
                body = 'Goodnight Moon 2',
                parentId = acct.id,
                ownerId = user2.id
            );

            insert note2;

        }

        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user2.isActive = false;
            update user2;

        }

        Test.startTest();

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable();

        Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

    }

    @isTest
    static void test_conversion_error() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Account acct = new Account(
            name = 'Test Account'
        );

        insert acct;

        Note note = new Note(
            title = 'Hello World 1',
            body = 'Hello World 1',
            parentId = acct.id
        );

        insert note;

        Test.startTest();

        ConvertNotesToContentNotesService.ConversionResult mockResult = new ConvertNotesToContentNotesService.ConversionResult();
        mockResult.status = ConvertNotesToContentNotesService.ConversionResultStatus.ERROR;
        mockResult.message = 'Mock Error Result';

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions( settings );

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable( options );

        batchable.mockResults = new List<ConvertNotesToContentNotesService.ConversionResult>{ mockResult };

        Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

    }

    @isTest
    static void test_conversion_exception() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Account acct = new Account(
            name = 'Test Account'
        );

        insert acct;

        Note note = new Note(
            title = 'Hello World 1',
            body = 'Hello World 1',
            parentId = acct.id
        );

        insert note;

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions( settings );

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable( options );

        batchable.mockException = new System.NullPointerException();

        Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

    }

    @isTest
    static void test_max_records_to_convert() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account acct = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert acct;

        Note note1 = new Note(
            title = 'Hello World 1',
            body = 'Hello World 1',
            parentId = acct.id,
            ownerid = user1.id
        );

        insert note1;

        Note note2 = new Note(
            title = 'Hello World 2',
            body = 'Hello World 2',
            parentId = acct.id,
            ownerId = user2.id
        );

        insert note2;

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions();
        options.maxRecordsToConvert = 1;

        ConvertNotesToContentNotesBatchable batchable = new ConvertNotesToContentNotesBatchable( options );
        batchable.conversionCount = options.maxRecordsToConvert;

        ID jobId = Database.executeBatch( batchable, 100 );

        Test.stopTest();

        for ( Convert_Notes_to_ContentNotes_Log__c log : [ SELECT Status__c, Old_Note_ID__c, New_Note_ID__c, Summary__c, Detail__c FROM Convert_Notes_to_ContentNotes_Log__c ] ) {
            System.debug( log );
        }

    }

}
