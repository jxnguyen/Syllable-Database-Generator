//
//  Brain.m
//  databaseGenerator
//
//  Created by John Nguyen on 12/10/2014.
//  Copyright (c) 2014 John Nguyen. All rights reserved.
//

#import "Brain.h"


@implementation Brain

//
// PARSE TEXT FILE - parses large text file, splits lines into array
//
+ (NSArray*) parseTextFileFromPath: (NSString*) filePath {
	
	// reads data from file
	NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath: filePath];
	uint64 offset = 0;
	uint32 chunkSize = 56;	// 1kb chunks
	
	// store lines from file
	NSMutableArray* lines = [[NSMutableArray alloc] init];
	
	NSLog(@"begining parse...");
	
	// read first chunk
	NSData* data = [handle readDataOfLength: chunkSize];
	
	// scan through file one chunk at a time
	while ([data length] > 0) {
		
		// choose appropriate string encoding
		NSString* dataString = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		
		// separte string at newline
		NSMutableArray* separatedStrings = [[dataString componentsSeparatedByString: @"\n"] mutableCopy];
		
		// if the string arrays have content
		if ([lines count] && [separatedStrings count]) {
			
			// join the first new string to the last stored string
			NSString* joinedString = [NSString stringWithFormat: @"%@%@", [lines lastObject], [separatedStrings firstObject]];
			
			// store sting to lines
			[lines replaceObjectAtIndex: [lines indexOfObject: [lines lastObject]]
							 withObject: joinedString];
			
			// remove the copied string
			[separatedStrings removeObjectAtIndex: 0];
		}
		
		// add separated strings to lines array
		[lines addObjectsFromArray: separatedStrings];
		
		// update offset
		offset += [data length];
		
		// get new data
		data = [handle readDataOfLength: chunkSize];
	}
	
	// close file
	[handle closeFile];
	
	NSLog(@"parse completed.");
	
	return lines;
}

//
// EXTRACT ORIGINAL WORD - the unhyphenated word
//
// expects a string with a minimum of two words separated by spaces
// to max of 6 words separated by spaces
//
+ (NSString*) extractOriginalWordFromLine: (NSString*) line {
	
	// split line by spaces
	NSArray* words = [line componentsSeparatedByString: @" "];
	
	int numberOfWords = (int)[words count];
	
	if (numberOfWords >= 2) {
		
		// take the first half
		switch (numberOfWords) {
			case 2:
				return [words firstObject];
				break;
			case 4:
				return [NSString stringWithFormat: @"%@ %@", [words firstObject], [words objectAtIndex: 1]];
				break;
			case 6:
				return [NSString stringWithFormat: @"%@ %@ %@", [words firstObject], [words objectAtIndex: 1], [words objectAtIndex: 2]];
				break;
			default:
				break;
		}
	}
	
	// default
	return [words firstObject];
}

//
// EXTRACT HYPHENATED WORD
//
// expects a string with a minimum of two words separated by spaces
// to max of 6 words separated by spaces. Also emits ; at end of last word
//
+ (NSString*) extractHyphenatedWordFromLine: (NSString*) line {
	
	// split line by spaces
	NSArray* words = [line componentsSeparatedByString: @" "];
	
	int numberOfWords = (int)[words count];
	
	if (numberOfWords >= 2) {
		
		// remove the semicolon at end of last word
		NSString* lastWord = [words lastObject];
		if ([lastWord length] > 0) {
			lastWord = [lastWord substringToIndex: [lastWord length] - 1];
		}
		
		// take the second half
		switch (numberOfWords) {
			case 2:
				return lastWord;
				break;
			case 4:
				return [NSString stringWithFormat: @"%@ %@", [words objectAtIndex: 2], lastWord];
				break;
			case 6:
				return [NSString stringWithFormat: @"%@ %@ %@", [words objectAtIndex: 3], [words objectAtIndex: 4], lastWord];
				break;
			default:
				break;
		}
	}
	
	// default
	return [words lastObject];
}

//
// COUNT SYLLABLES
//
// all words have at least one syllable. count hyphens and spaces
// eg. "tuy-key man" = 1 + 1 hyphen + 1 space
//
+ (int) numberOfSyllablesOfWord: (NSString*) hyphenatedWord {
	
	int spaces = 0;
	int hyphens = 0;
	
	spaces = (int)[[hyphenatedWord componentsSeparatedByString: @" "] count] - 1;
	hyphens = (int)[[hyphenatedWord componentsSeparatedByString: @"-"] count] - 1;
	
	return 1 + spaces + hyphens;
}

//
// DICTIONARY FROM ITEMS
//
// returns an array of dictionary['word' : peanut, "syllables : 2] from items
//
+ (NSArray*) dictionariesFromLines: (NSArray*) linesOfText {
	
	NSLog(@"creating dictionaries...");
	
	NSMutableArray* dictionaries = [[NSMutableArray alloc] init];
	
	for (NSString* line in linesOfText) {
		
		NSString* originalWord = [self extractOriginalWordFromLine: line];
		NSString* hyphenatedWord = [self extractHyphenatedWordFromLine: line];
		NSNumber* syllables = [[NSNumber alloc] initWithInt: [self numberOfSyllablesOfWord: hyphenatedWord]];
		NSDictionary* dict = @{ @"word": originalWord, @"syllables": syllables };
		[dictionaries addObject: dict];
	}
	
	NSLog(@"dictionaries completed...");
	return dictionaries;
}

//
// WORD HAS APOSTROPHES?
//
+ (int) numberOfApostrophesInWord:(NSString*) word {
	
	NSArray* components = [word componentsSeparatedByString: @"'"];
	
	return (int)[components count] - 1;
}

//
// ESCAPE APOSTROPHES - with extra '. single apostrophes invalidate SQL statements.
//
// NOTE: only escapes a maximum of three apostrophes!
//
+ (NSString*) escapeApostrophesInWord:(NSString*) word {
	
	int numberOfApostrophes = [self numberOfApostrophesInWord: word];
	
	if (numberOfApostrophes > 0) {
		
		// split components (apostrophes not included)
		NSArray* components = [word componentsSeparatedByString: @"'"];
		
		NSString* finalString;
		
		// recombine words with escaped apostrophes ('')
		switch (numberOfApostrophes) {
			case 1:
				finalString = [NSString stringWithFormat: @"%@''%@", [components firstObject], [components lastObject]];
				break;
			case 2:
				finalString = [NSString stringWithFormat: @"%@''%@''%@", [components firstObject], [components objectAtIndex: 1], [components lastObject]];
				break;
			case 3:
				finalString = [NSString stringWithFormat: @"%@''%@''%@''%@", [components firstObject], [components objectAtIndex: 1], [components objectAtIndex: 2], [components lastObject]];
				break;
			default:
				NSLog(@"Error: 0 or more than 3 apostrophes detected");
				break;
		}
		return finalString;
	}
	// unchanged word
	return word;
}

@end
