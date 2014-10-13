//
//  Brain.h
//  databaseGenerator
//
//  Created by John Nguyen on 12/10/2014.
//  Copyright (c) 2014 John Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Brain : NSObject

+ (NSArray*) parseTextFileFromPath:(NSString*) filePath;
+ (NSString*) extractOriginalWordFromLine:(NSString*) line;
+ (NSString*) extractHyphenatedWordFromLine:(NSString*) line;
+ (int) numberOfSyllablesOfWord:(NSString*) hyphenatedWord;
+ (NSArray*) dictionariesFromLines:(NSArray*) linesOfText;
+ (int) numberOfApostrophesInWord:(NSString*) word;
+ (NSString*) escapeApostrophesInWord:(NSString*) word;


@end
