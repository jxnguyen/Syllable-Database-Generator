//
//  main.m
//  databaseGenerator
//
//  Created by John Nguyen on 12/10/2014.
//  Copyright (c) 2014 John Nguyen. All rights reserved.
//
//
//	DESCRIPTION:
/*
 DESCRIPTION:
 
 This program opens a hyphenated dictionary text file and iterates through
 the file to count the number of syllables of each word. The word and its 
 syllable count is then stored inside a SQL database and saved to a specified 
 file path (as 'data.db')
 
 EXPECTATIONS:
 
 The dictionary to be read must be a .txt file. The format of this dictionary
 is as follows:
 
	cat cat;
	peanut pea-nut;
	monkey man mon-key man;
 
 The original word(s) is first, the hyphenated version is second, separated
 by a space and terminated with a semicolon. Any duplications of words will
 be excluded, as the SQL table storing the data is UNIQUE INDEXED. All words
 will be converted to lowercase to avoid unneccessary duplicates (since "Cat"
 & "cat" are considered to be unique)
 
 Filepaths, SQL Table name and SQL Column names can be specified below
 
 */
//	This progmram iterates through a hyphenated dictionary to count
//	the number of syllables of each word. It converts a text file dictionary
//	of hyphenated words into a plist. The format of the input file (dictionary)
//	must follow the format:
//
//			"aardvark aard-vark;"	(note: ';' is optional)
//
//	Additionally, there may only be a maximum of two word combinations
//	eg. "Bird man"
//
//	The ouput file is a plist, formatted as an array of dictionaries,
//	each of which has the keys "word" & "syllables", paired with the values
//	of type String & Real (integer number) respeciveley
//
//	Two command line arguments must be supplied, the infile and the outfile.

#import <Foundation/Foundation.h>
#include <sqlite3.h>
#include "DBManager.h"
#include "Brain.h"

// CONSTANTS
NSString* filePath = @"/Users/johnnguyen/Documents/PROJECTS/XCode/Projects/databaseGenerator/databaseGenerator/EnglishHyphenDictionary.txt";
NSString* samplePath = @"/Users/johnnguyen/Documents/PROJECTS/XCode/Projects/databaseGenerator/databaseGenerator/sample.txt";
NSString* outfilePath = @"/Users/johnnguyen/Documents/PROJECTS/XCode/Projects/databaseGenerator/databaseGenerator/output/data.db";

#define TABLE_NAME @"dictionary"
#define COLUMN_1_NAME @"word"
#define COLUMN_2_NAME @"syllables"


int main(int argc, const char * argv[]) {
	@autoreleasepool {
		
		// parse the text file
		NSArray* linesOfText = [Brain parseTextFileFromPath: filePath];
		NSArray* dictionaries = [Brain dictionariesFromLines: linesOfText];
		
		// set up database manager
		DBManager* databaseManager = [[DBManager alloc] init];
		databaseManager.databasePath = outfilePath;
		databaseManager.tableName = TABLE_NAME;
		databaseManager.firstColumnName = COLUMN_1_NAME;
		databaseManager.secondColumnName = COLUMN_2_NAME;
		
		// create/open database, create table
		[databaseManager openDatabase];
		[databaseManager createDictionariesTable];
		
		int successfulSaves = 0;
		int failedSaves = 0;
		
		NSLog(@"begining saves...");
		
		// add data to database
		for (NSDictionary* dict in dictionaries) {
			
			NSString* word = dict[databaseManager.firstColumnName];
			
			// check for apostrophes (must escape to comply with sql statements)
			if ([Brain numberOfApostrophesInWord: word] > 0) {
    
				// escape apostrophes with extra '
				word = [Brain escapeApostrophesInWord: word];
				NSDictionary* newDict = @{ databaseManager.firstColumnName: word,
										   databaseManager.secondColumnName: dict[databaseManager.secondColumnName] };
				
				// save word in database
				if ([databaseManager saveWordData: newDict])
					successfulSaves++;
				else
					failedSaves++;
				
			} else {
				
				// note: if word already exist save is unsuccessful
				if ([databaseManager saveWordData: dict])
					successfulSaves++;
				else
					failedSaves++;
			}			
		}
		
		NSLog(@"SUCCESSFUL SAVES: %i    FAILED SAVES: %i", successfulSaves, failedSaves);
		
		[databaseManager closeDatabase];
		
		// TEST RETRIEVAL
		//[databaseManager findWord: @"dasher"];
		
	}
    return 0;
}



