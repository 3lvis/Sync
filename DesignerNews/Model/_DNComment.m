// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DNComment.m instead.

#import "_DNComment.h"

const struct DNCommentAttributes DNCommentAttributes = {
	.body = @"body",
	.depth = @"depth",
	.upvotesCount = @"upvotesCount",
	.userDisplayName = @"userDisplayName",
};

const struct DNCommentRelationships DNCommentRelationships = {
	.comments = @"comments",
	.story = @"story",
};

@implementation DNCommentID
@end

@implementation _DNComment

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Comment";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Comment" inManagedObjectContext:moc_];
}

- (DNCommentID*)objectID {
	return (DNCommentID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"depthValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"depth"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"upvotesCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"upvotesCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic body;

@dynamic depth;

- (int16_t)depthValue {
	NSNumber *result = [self depth];
	return [result shortValue];
}

- (void)setDepthValue:(int16_t)value_ {
	[self setDepth:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveDepthValue {
	NSNumber *result = [self primitiveDepth];
	return [result shortValue];
}

- (void)setPrimitiveDepthValue:(int16_t)value_ {
	[self setPrimitiveDepth:[NSNumber numberWithShort:value_]];
}

@dynamic upvotesCount;

- (int32_t)upvotesCountValue {
	NSNumber *result = [self upvotesCount];
	return [result intValue];
}

- (void)setUpvotesCountValue:(int32_t)value_ {
	[self setUpvotesCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUpvotesCountValue {
	NSNumber *result = [self primitiveUpvotesCount];
	return [result intValue];
}

- (void)setPrimitiveUpvotesCountValue:(int32_t)value_ {
	[self setPrimitiveUpvotesCount:[NSNumber numberWithInt:value_]];
}

@dynamic userDisplayName;

@dynamic comments;

- (NSMutableSet*)commentsSet {
	[self willAccessValueForKey:@"comments"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"comments"];

	[self didAccessValueForKey:@"comments"];
	return result;
}

@dynamic story;

@end

