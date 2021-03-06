//
//  IFRuntimeErrorParser.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFRuntimeErrorParser.h"


@implementation IFRuntimeErrorParser {
    id delegate;								// The delegate
    NSMutableString* accumulator;				// The character accumulator
}

- (instancetype) init {
	self = [super init];
	
	if (self) {
		accumulator = [[NSMutableString alloc] init];
	}
	
	return self;
}


- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (void) outputText: (NSString*) outputText {
	// Scan for '*** Run-time problem XX' at the beginning of a line: this indicates that runtime problem XX
	// has occured (and we should probably be showing file RTP_XX.html)
	NSString* runtimeIndicator = @"*** Run-time problem ";
	NSString* problemType = nil;
	
	int len = (int) [outputText length];
	int pos;
	int indicatorLen = (int) [runtimeIndicator length];
	
	for (pos = 0; pos<len-indicatorLen-1; pos++) {
		unichar chr = [outputText characterAtIndex: pos];
		
		if (chr == '\n') {
			// Characters following pos might be the run-time problem indicator
			NSString* mightMatch = [outputText substringWithRange: NSMakeRange(pos+1, indicatorLen)];
			
			if ([mightMatch isEqualToString: runtimeIndicator]) {
				// We've got a match for the string: find the problem identifier
				pos += indicatorLen+1;
				
				int startOfId = pos;
				for (;pos<len; pos++) {
					chr = [outputText characterAtIndex: pos];
					
					if (chr == ' ' || chr == '\t' || chr == '\n' || chr == '\r' || chr == ':') {
						// We've found the end of the ID
						break;
					}
					
					// Copy the problem type
					problemType = [outputText substringWithRange: NSMakeRange(startOfId, pos-startOfId+1)];
				}
				
				break;
			}
		}
	}
	
	if (problemType != nil) {
		// A problem was encountered: inform the delegate
		if (delegate && [delegate respondsToSelector: @selector(runtimeError:)]) {
			[delegate runtimeError: problemType];
		}
	}
}

// Notifications about events that have occured in the view (when using this automation object for output)

- (void) receivedCharacters: (NSString*) characters					// Text has arrived at the specified text buffer window (from the game)
					 window: (int) windowNumber
				   fromView: (GlkView*) view {
	unichar* chrs = malloc(sizeof(unichar)*[characters length]);
    if( chrs != NULL ) {
        [characters getCharacters: chrs];
        
        int start = 0;
        int x;
        for (x=0; x<[characters length]; x++) {
            if (chrs[x] == '\n') {
                [accumulator appendString: [NSString stringWithCharacters: chrs + start
                                                                   length: x - start]];
                
                [self outputText: accumulator];
                accumulator = [[NSMutableString alloc] init];
                start = x;
            }
        }
        [accumulator appendString: [NSString stringWithCharacters: chrs + start
                                                           length: x - start]];
        
        [accumulator appendString: characters];
        [self outputText: characters];
    }
    free(chrs);
}

- (void) userTyped: (NSString*) userInput							// The user has typed the specified string into the specified window (which is any window that is waiting for input)
			window: (int) windowNumber
		 lineInput: (BOOL) isLineInput
		  fromView: (GlkView*) view {
}

- (void) userClickedAtXPos: (int) xpos								// The user has clicked at a specified position in the given window
					  ypos: (int) ypos
					window: (int) windowNumber
				  fromView: (GlkView*) view {
}

- (void) viewWaiting: (GlkView*) view {
	}

// Using this automation object for input

- (void) viewIsWaitingForInput: (GlkView*) view {
	
}

@end
