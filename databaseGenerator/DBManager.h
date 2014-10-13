//
//  DBManager.h
//  databaseGenerator
//
//  Created by John Nguyen on 12/10/2014.
//  Copyright (c) 2014 John Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sqlite3.h>

@interface DBManager : NSObject 

@property NSString* databasePath;
@property NSString* tableName;
@property NSString* firstColumnName;
@property NSString* secondColumnName;

+ (DBManager*) getSharedInstance;
- (BOOL) openDatabase;
- (BOOL) createDictionariesTable;
- (BOOL) saveWordData:(NSDictionary*) wordDictionary;
- (BOOL) findWord:(NSString*) word;
- (void) closeDatabase;

static int callback(void *NotUsed, int argc, char **argv, char **azColName);



@end
