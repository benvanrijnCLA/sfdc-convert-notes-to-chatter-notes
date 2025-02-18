/**
 * Developed by Doug Ayers (douglascayers.com)
 */
@isTest
private class ConvertNotesToContentNotesServiceTest {

    @isTest
    static void test_special_characters() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'System Administrator' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note emptyNote = new Note(
                title = 'Hello World.txt',
                body = '',
                parentId = account.id,
                ownerId = user1.id,
                createdById = user1.id
        );

        Note plainNote = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note specialTitleNote = new Note(
            title = 'Hello ! @ # $ % ^ & * ( )  + = - _ \' \" , . ? / \\ [ ] { } | ` ~ < > ¢ © ®',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note specialBodyNote = new Note(
            title = 'Hello World.txt',
            body = 'Hello ! @ # $ % ^ & * ( )  + = - _ \' \" , . ? / \\ [ ] { } | ` ~ < > ¢ © ®',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note specialTitleAndBodyNote = new Note(
            title = 'Hello ! @ # $ % ^ & * ( )  + = - _ \' \" , . ? / \\ [ ] { } | ` ~ < > ¢ © ®',
            body = 'Hello ! @ # $ % ^ & * ( )  + = - _ \' \" , . ? / \\ [ ] { } | ` ~ < > ¢ © ®',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note htmlBodyNote = new Note(
            title = 'Hello World.html',
            body = '<b>bold</b> <u>underline</u> <i>italic</i> <ul><li>list item</li></ul> <ol><li>list item</li></ol> <a href="www.salesforce.com">link</a> <div></div> <p></p> &nbsp; &copy; &trade; <span style="color:red">text</span> <img src="image.png"/>',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note githubIssue8 = new Note(
            title = 'Meeting Agenda 2016-06-16 agenda.pdf',
            body = 'Meeting Agenda 2016-06-16 agenda.pdf',
            parentId = account.id,
            ownerId = user1.id,
            createdById = user1.id
        );

        Note[] notes = new Note[] { emptyNote, plainNote, specialTitleNote, specialBodyNote, specialTitleAndBodyNote, htmlBodyNote, githubIssue8 };

        // ensure user1 owns the records
        System.runAs( user1 ) {
            insert notes;
        }

        notes = [
            SELECT
                id, parentId, ownerId, title, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Note
            WHERE
                id = :notes
        ];

        Test.startTest();

        List<ConvertNotesToContentNotesService.ConversionResult> results = null;

        System.runAs( user1 ) {

            ConvertNotesToContentNotesService service = new ConvertNotesToContentNotesService();

            results = service.convert( notes );

        }

        Test.stopTest();



        for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
            System.debug( result );
        }

    }

    @isTest
    static void test_convert_real_time() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = true;
        settings.Delete_Note_Once_Converted__c = false;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'Standard User' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note note = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id
        );

        Test.startTest();

        insert note;

        Test.stopTest();

        System.runAs( user1 ) {

            ContentVersion cv = [ SELECT id, contentDocumentId, sharingPrivacy FROM ContentVersion WHERE original_record_id__c = :note.id AND isLatest = true ];
            

            ContentDocumentLink cdl = [ SELECT id, linkedEntityId FROM ContentDocumentLink WHERE contentDocumentId = :cv.contentDocumentId AND linkedEntityId = :account.id ];
            

            ContentNote cn = [ SELECT id, latestPublishedVersionId FROM ContentNote WHERE latestPublishedVersionId = :cv.id ];
            

            List<Note> notes = new List<Note>([ SELECT id FROM Note WHERE id = :note.id ]);
            

            UserRecordAccess user2access = [ SELECT recordId, hasReadAccess FROM UserRecordAccess WHERE userId = :user2.id AND recordId = :cv.id ];
            

        }

    }

    @isTest
    static void test_no_delete() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = false;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'Standard User' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note note = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id
        );

        insert note;

        note = [
            SELECT
                id, parentId, ownerId, title, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Note
            WHERE
                id = :note.id
        ];

        Test.startTest();

        ConvertNotesToContentNotesService service = new ConvertNotesToContentNotesService();

        List<ConvertNotesToContentNotesService.ConversionResult> results = service.convert( new Note[]{ note } );

        Test.stopTest();

        

        for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
            System.debug( result );
            
        }

        System.runAs( user1 ) {

            ContentVersion cv = [ SELECT id, contentDocumentId FROM ContentVersion WHERE original_record_id__c = :note.id AND isLatest = true ];
            

            ContentDocumentLink cdl = [ SELECT id, linkedEntityId FROM ContentDocumentLink WHERE contentDocumentId = :cv.contentDocumentId AND linkedEntityId = :account.id ];
            

            ContentNote cn = [ SELECT id, latestPublishedVersionId FROM ContentNote WHERE latestPublishedVersionId = :cv.id ];
            

            List<Note> notes = new List<Note>( [ SELECT id FROM Note WHERE id = :note.id ] );
            

        }

    }

    @isTest
    static void test_yes_delete() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'Standard User' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note note = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id
        );

        insert note;

        note = [
            SELECT
                id, parentId, ownerId, title, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Note
            WHERE
                id = :note.id
        ];

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions();
        options.deleteNotesUponConversion = true;

        ConvertNotesToContentNotesService service = new ConvertNotesToContentNotesService( options );

        List<ConvertNotesToContentNotesService.ConversionResult> results = service.convert( new Note[]{ note } );

        Test.stopTest();

        

        for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
            System.debug( result );
            
        }

        System.runAs( user1 ) {

            ContentVersion cv = [ SELECT id, contentDocumentId FROM ContentVersion WHERE original_record_id__c = :note.id AND isLatest = true ];
            

            ContentDocumentLink cdl = [ SELECT id, linkedEntityId FROM ContentDocumentLink WHERE contentDocumentId = :cv.contentDocumentId AND linkedEntityId = :account.id ];
            

            ContentNote cn = [ SELECT id, latestPublishedVersionId FROM ContentNote WHERE latestPublishedVersionId = :cv.id ];
            

            List<Note> notes = new List<Note>( [ SELECT id FROM Note WHERE id = :note.id ] );
            

        }

    }

    @isTest
    static void test_share_private_notes_with_parent_record() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'Standard User' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note note = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id,
            isPrivate = true
        );

        insert note;

        note = [
            SELECT
                id, parentId, ownerId, title, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Note
            WHERE
                id = :note.id
        ];

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions();

        ConvertNotesToContentNotesService service = new ConvertNotesToContentNotesService( options );

        List<ConvertNotesToContentNotesService.ConversionResult> results = service.convert( new Note[]{ note } );

        Test.stopTest();

        System.runAs( user1 ) {

            

            for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
                System.debug( result );
                
            }

            ContentVersion cv = [ SELECT id, contentDocumentId, sharingPrivacy FROM ContentVersion WHERE original_record_id__c = :note.id AND isLatest = true ];
            

            ContentDocumentLink cdl = [ SELECT id, linkedEntityId FROM ContentDocumentLink WHERE contentDocumentId = :cv.contentDocumentId AND linkedEntityId = :account.id ];
            

            UserRecordAccess user2access = [ SELECT recordId, hasReadAccess FROM UserRecordAccess WHERE userId = :user2.id AND recordId = :cv.id ];
            

        }

    }

    @isTest
    static void test_no_duplicates() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = false;
        settings.Delete_Note_Once_Converted__c = false;

        upsert settings;

        UserRole role = [ SELECT id FROM UserRole WHERE parentRoleId = null AND portalType = 'None' LIMIT 1 ];

        Profile p = [ SELECT id FROM Profile WHERE name = 'Standard User' ];

        User user1, user2;

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_tools_runas.htm
        System.runAs( new User( id = UserInfo.getUserId() ) ) {

            user1 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Alpha', 'User 1', 'user_1@example.com' );
            user2 = ConvertNotesToContentNotesTestFactory.newUser( p.id, role.id, 'Beta',  'User 2', 'user_2@example.com' );

            insert new List<User>{ user1, user2 };

        }

        Account account = new Account(
            ownerId = user1.id,
            name = 'Test Account'
        );

        insert account;

        Note note = new Note(
            title = 'Hello World.txt',
            body = 'Goodnight Moon',
            parentId = account.id,
            ownerId = user1.id
        );

        System.runAs( user1 ) {

            insert note;

        }

        note = [
            SELECT
                id, parentId, ownerId, title, body, isPrivate,
                createdById, createdDate, lastModifiedById, lastModifiedDate
            FROM
                Note
            WHERE
                id = :note.id
        ];

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions();

        ConvertNotesToContentNotesService service = new ConvertNotesToContentNotesService( options );

        List<ConvertNotesToContentNotesService.ConversionResult> results = service.convert( new Note[]{ note } );

        for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
            System.debug( result );
            
        }



        // convert again, expect no duplicate file created

        results = service.convert( new Note[]{ note } );

        for ( ConvertNotesToContentNotesService.ConversionResult result : results ) {
            System.debug( result );
            
        }

        

        Test.stopTest();

    }

    @isTest
    static void test_init_options_from_settings() {

        Convert_Notes_to_ContentNotes_Settings__c settings = Convert_Notes_to_ContentNotes_Settings__c.getOrgDefaults();
        settings.Convert_in_Near_Real_Time__c = true;
        settings.Delete_Note_Once_Converted__c = true;

        upsert settings;

        Test.startTest();

        ConvertNotesToContentNotesOptions options = new ConvertNotesToContentNotesOptions( settings );

        Test.stopTest();

        

    }

}
