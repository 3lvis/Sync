// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DNStory.m instead.

#import "_DNStory.h"

const struct DNStoryAttributes DNStoryAttributes = {
	.commentsCount = @"commentsCount",
	.createdAt = @"createdAt",
	.remoteID = @"remoteID",
	.title = @"title",
};

const struct DNStoryRelationships DNStoryRelationships = {
	.comments = @"comments",
};

@implementation DNStoryID
@end

@implementation _DNStory

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Story" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Story";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Story" inManagedObjectContext:moc_];
}

- (DNStoryID*)objectID {
	return (DNStoryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"commentsCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"commentsCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"remoteIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"remoteID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic commentsCount;

- (int32_t)commentsCountValue {
	NSNumber *result = [self commentsCount];
	return [result intValue];
}

- (void)setCommentsCountValue:(int32_t)value_ {
	[self setCommentsCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveCommentsCountValue {
	NSNumber *result = [self primitiveCommentsCount];
	return [result intValue];
}

- (void)setPrimitiveCommentsCountValue:(int32_t)value_ {
	[self setPrimitiveCommentsCount:[NSNumber numberWithInt:value_]];
}

@dynamic createdAt;

@dynamic remoteID;

- (int32_t)remoteIDValue {
	NSNumber *result = [self remoteID];
	return [result intValue];
}

- (void)setRemoteIDValue:(int32_t)value_ {
	[self setRemoteID:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveRemoteIDValue {
	NSNumber *result = [self primitiveRemoteID];
	return [result intValue];
}

- (void)setPrimitiveRemoteIDValue:(int32_t)value_ {
	[self setPrimitiveRemoteID:[NSNumber numberWithInt:value_]];
}

@dynamic title;

@dynamic comments;

- (NSMutableSet*)commentsSet {
	[self willAccessValueForKey:@"comments"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"comments"];

	[self didAccessValueForKey:@"comments"];
	return result;
}

@end

