//
//  DBManager.m
//  databaseGenerator
//
//  Created by John Nguyen on 12/10/2014.
//  Copyright (c) 2014 John Nguyen. All rights reserved.
//

#import "DBManager.h"

static DBManager* sharedInstance = nil;
static sqlite3* database = nil;
static sqlite3_stmt* statement = nil;


@implementation DBManager

//
// GET SHARED INSTANCE
//
+ (DBManager*) getSharedInstance {
	
	if (!sharedInstance) {
		sharedInstance = [[super allocWithZone: NULL] init];
		[sharedInstance openDatabase];
	}
	return sharedInstance;
}

//
// OPEN DATABASE - open or create if not existent
//
- (BOOL) openDatabase {
	
	if (sqlite3_open([_databasePath UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Database failed to open");
		return NO;
		
	} else {
		NSLog(@"Database opened successfully");
		return YES;
	}
}

//
// CREATE TABLE NAMED - first field is "word", secondField is "syllables"
//
- (BOOL) createDictionariesTable {
	
	
	char *error;
	
	// create sql statement
	NSString* createSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@'('%@' TEXT PRIMARY KEY, '%@' REAL);", _tableName, _firstColumnName, _secondColumnName];
	const char* sql_statement = [createSQL UTF8String];
	
	// execute statement
	if (sqlite3_exec(database, sql_statement, NULL, NULL, &error) != SQLITE_OK) {
		
		sqlite3_close(database);
		NSAssert(0, @"Table failed to create");
		return NO;
		
	} else {
		
		// index table
		NSString* index_statement = [NSString stringWithFormat: @"CREATE INDEX word_index ON '%@'('%@');", _tableName, _firstColumnName];
		const char* sql_statement = [index_statement UTF8String];
		
		if (sqlite3_exec(database, sql_statement, NULL, NULL, &error) != SQLITE_OK) {
			
			NSLog(@"Table created successfully, but indexing failed");
			return NO;
		} else {
			
			NSLog(@"Table sucessfully created and indexed");
			return YES;
		}
	}
}

//
// SAVE WORD - saves "word", "syllables" into "dictionary"
//
// NOTE: Save only successful if word does not exist (must be unique!).
// since table is word is unique indexed, this avoids duplicates (case sensitive)
// eg. "Aaron" != "aaron", both will be saved.
//
- (BOOL) saveWordData:(NSDictionary*) wordDictionary {
	
	char* error;
	
	// data to store
	NSString* word = wordDictionary[@"word"];
	NSNumber* syllables = wordDictionary[@"syllables"];
	
	// convert all words to lowercase
	word = [word lowercaseString];
	
	// create statement
	NSString* insertSQL = [NSString stringWithFormat: @"INSERT INTO '%@'('%@','%@') VALUES('%@', %@)", _tableName, _firstColumnName, _secondColumnName, word, syllables];
	
	const char* insert_statement = [insertSQL UTF8String];
	
	if (sqlite3_exec(database, insert_statement, callback, 0, &error) == SQLITE_OK) {
		
		return YES;
	
	} else {
		NSLog(@"Save unsuccessful for word: %@", word);
		
		// error message
		fprintf(stderr, "SQL error: %s, WORD: %s\n", error, [word UTF8String]);
		sqlite3_free(error);
		
		return NO;
	}
}

//
// FIND WORD
//
- (BOOL) findWord:(NSString*) word {
	
	BOOL isSuccessful = NO;
	
	// create statement
	NSString* sql_query = [NSString stringWithFormat: @"SELECT * FROM %@ WHERE %@ LIKE \"%@\"", _tableName, _firstColumnName, word];
	const char* sql_statement = [sql_query UTF8String];
	
	// execute statement
	if (sqlite3_prepare_v2(database, sql_statement, -1, &statement, NULL) == SQLITE_OK) {
		
		if (sqlite3_step(statement) == SQLITE_ROW) {
			
			NSString* word = [[NSString alloc] initWithUTF8String: (const char*)sqlite3_column_text(statement, 0)];
			NSNumber* syllables = [[NSNumber alloc] initWithInt: sqlite3_column_int(statement, 1)];
			NSLog(@"Success! The word '%@' has %@ syllables", word, syllables);
			sqlite3_reset(statement);
			isSuccessful = YES;
			
		} else {
			
			NSLog(@"The word '%@' was not found", word);
			sqlite3_reset(statement);
			
			isSuccessful = NO;
		}
	}
	return isSuccessful;
}

//
// CLOSE DATABASE
//
- (void) closeDatabase {
	
	sqlite3_close(database);
	NSLog(@"Database closed.");
}

static int callback(void *NotUsed, int argc, char **argv, char **azColName) {
	int i;
	for(i = 0; i < argc; i++) {
		printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
	}
	printf("\n");
	return 0;
}


@end
