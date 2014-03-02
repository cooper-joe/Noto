//
//  BPTextView.m
//  TipTyper
//
//  Created by Bruno Philipe on 2/23/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "BPTextView.h"

@interface BPTextView ()

@end

@implementation BPTextView

- (NSUInteger)locationOfPreviousNewLineFromLocation:(NSUInteger)location;
{
	location--;

	NSUInteger index = location;
	NSString *string = self.string;
	unichar chr = '\0';
	BOOL found = NO;

	while (!found && (NSInteger)index >= 0) {
		if (index < string.length)
		{
			chr = [string characterAtIndex:index];
			if (chr == '\n' || chr == '\r') {
				found = YES;
			} else {
				index--;
			}
		}
	}

	return index;
}

- (NSUInteger)locationOfNextNewLineFromLocation:(NSUInteger)location;
{
	NSUInteger index = location;
	NSString *string = self.string;
	unichar chr = '\0';
	BOOL found = NO;

	while (!found && index < string.length) {
		chr = [string characterAtIndex:index];
		if (chr == '\n' || chr == '\r') {
			found = YES;
		} else {
			index++;
		}
	}

	return index+1;
}

- (NSUInteger)countTabCharsFromLocation:(NSUInteger)location
{
	NSUInteger count = 0, spaces = 0;
	NSString *string = self.string;
	unichar chr = '\0';
	BOOL finished = NO;

	while (!finished && location < string.length-1) {
		chr = [string characterAtIndex:location];
		if (chr == '\t') {
			count++;
			location++;
		} else if (chr == ' ') {
			spaces++;
			location++;
		} else {
			finished = YES;
		}
	}

	return count + spaces/self.tabSize;
}

- (NSString*)buildStringWithTabsCount:(NSUInteger)count
{
	NSMutableString *str = [NSMutableString stringWithCapacity:count];
	for (NSUInteger i=0; i<count; i++) {
		[str appendString:@"\t"];
	}
	return [str copy];
}

- (NSString*)buildStringWithSpacesCount:(NSUInteger)count
{
	NSMutableString *str = [NSMutableString stringWithCapacity:count];
	for (NSUInteger i=0; i<count; i++) {
		[str appendString:@" "];
	}
	return [str copy];
}

- (void)keyDown:(NSEvent *)theEvent
{
	[super keyDown:theEvent];

	if (self.shouldInsertTabsOnLineBreak && theEvent.keyCode == 36) {
		NSRange range = [self rangeForUserTextChange];
		NSString *string = self.string;
		NSUInteger location, count;
		unichar chr;

		if (range.location-1 < string.length) {
			chr = [string characterAtIndex:range.location-1];
			if (chr == '\n') {
				location = [self locationOfPreviousNewLineFromLocation:range.location-1];
				count = [self countTabCharsFromLocation:location+1];

				if (self.shouldInsertSpacesInsteadOfTabs) {
					[self insertText:[self buildStringWithSpacesCount:count * self.tabSize]];
				} else {
					[self insertText:[self buildStringWithTabsCount:count]];
				}
			}
		}
	}
}

- (void)insertTab:(id)sender
{
	if (self.shouldInsertSpacesInsteadOfTabs) {
		[self insertText:[self buildStringWithSpacesCount:self.tabSize]];
	} else {
		[super insertTab:sender];
	}
}

- (void)iterateThroughLinesUsingBlock:(void(^)(NSUInteger location, NSInteger *difference))block
{
	NSUInteger initialLocation = 0, location = 0;
	NSRange range;
	NSInteger count = 0, previousCount = 0;
	NSMutableArray *ranges = [NSMutableArray array];
	NSInteger difference, diffRange;

	for (NSValue *rangeVal in [self selectedRanges]) {
		previousCount += count;
		count = 0;

		range = [rangeVal rangeValue];
		range.location += previousCount;
		location = initialLocation = [self locationOfPreviousNewLineFromLocation:range.location] + 1;

		while (location < initialLocation + range.length + count + 1) {
			difference = 0;
			block(location, &difference);
			location = [self locationOfNextNewLineFromLocation:location];
			count += difference;
		}

		diffRange = (count == 0 ? 0 : (count < 0 ? 1 : -1));
		range = NSMakeRange((range.location < diffRange ? 0 : range.location - diffRange), range.length + count + diffRange);

		[ranges addObject:[NSValue valueWithRange:range]];
	}

	[self setSelectedRanges:ranges];
}

- (void)increaseIndentation
{
	[self iterateThroughLinesUsingBlock:^(NSUInteger location, NSInteger *difference) {
		[self increaseIndentationAtLocation:location];
		*difference = 1;
	}];
}

- (void)increaseIndentationAtLocation:(NSUInteger)location
{
	if (self.shouldInsertSpacesInsteadOfTabs) {
		[self insertText:[self buildStringWithSpacesCount:self.tabSize] replacementRange:NSMakeRange(location, 0)];
	} else {
		[self insertText:[self buildStringWithTabsCount:1] replacementRange:NSMakeRange(location, 0)];
	}
}

- (void)decreaseIndentation
{
	[self iterateThroughLinesUsingBlock:^(NSUInteger location, NSInteger *difference) {
		*difference = ([self decreaseIndentationAtLocation:location] ? -1 : 0);
	}];
}

- (BOOL)decreaseIndentationAtLocation:(NSUInteger)location
{
	NSUInteger count = [self countTabCharsFromLocation:location];

	if (count > 0) {
		if (self.shouldInsertSpacesInsteadOfTabs) {
			[self insertText:@"" replacementRange:NSMakeRange(location, self.tabSize)];
		} else {
			[self insertText:@"" replacementRange:NSMakeRange(location, 1)];
		}

		return YES;
	}

	return NO;
}

@end
