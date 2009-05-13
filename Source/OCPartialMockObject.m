//---------------------------------------------------------------------------------------
//  $Id: OCPartialMockObject.m $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCPartialMockObject.h"
#import <objc/objc-runtime.h>
#import "OCPartialMockRecorder.h"
 static NSMutableDictionary *_OCPartialMockShadowObjects;
 static NSInteger _OCPartialMockClassSequence;

@interface OCPartialMockForwardingHolder : NSObject {
	
}
- (void) forwardToShadow: (NSInvocation *) invocation;
- (id) expect;
- (id) stub;
@end
@implementation OCPartialMockForwardingHolder 

- (void) forwardToShadow: (NSInvocation *) invocation {
	id shadow = [_OCPartialMockShadowObjects objectForKey:[NSString stringWithCString:object_getClassName([invocation target])]];
	[shadow forwardInvocation:invocation];
}
- (id) expect {
	OCMockObject *shadow = [_OCPartialMockShadowObjects objectForKey:[NSString stringWithCString:object_getClassName(self)]];
	return [shadow expect];
}
- (id) stub {
	OCMockObject *shadow = [_OCPartialMockShadowObjects objectForKey:[NSString stringWithCString:object_getClassName(self)]];
	return [shadow stub];
}

@end


@interface OCMockObject(Private)
+ (id)partialMockWithObject:(NSObject *)anObject;
+ (id)_makeNice:(OCMockObject *)mock;
- (BOOL)_handleRecordedInvocations:(NSInvocation *)anInvocation;
- (NSString *)_recorderDescriptions:(BOOL)onlyExpectations;
- (void) addRecorder:(OCMockRecorder *) recorder;
@end

@implementation OCPartialMockObject

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

+ (NSInteger) nextSequence {
	_OCPartialMockClassSequence += 1;
	return _OCPartialMockClassSequence - 1;
}

+ (void) shadowObject: (id) anObject withMock: (id) mock {
	if (nil == _OCPartialMockShadowObjects ) {
		_OCPartialMockShadowObjects = [NSMutableDictionary new];
	}
	[_OCPartialMockShadowObjects setObject:mock forKey: [NSString stringWithCString:object_getClassName(anObject)]];
}

+ (id)partialMockWithObject:(NSObject *)anObject {
	NSString *objectIdentifier = [NSString stringWithFormat:@"Mock%d%s",[OCPartialMockObject nextSequence],class_getName([anObject class])];
	Class subclass = objc_allocateClassPair([anObject class], [objectIdentifier cStringUsingEncoding:NSASCIIStringEncoding], 0);
	
	id mockObject = [[OCPartialMockObject alloc] initWithObject:anObject];

	// Hook up the forwarder
	IMP myForwarder = class_getMethodImplementation([OCPartialMockForwardingHolder class],@selector(forwardToShadow:));

	Method mf = class_getInstanceMethod([mockObject class], @selector(forwardToShadow:));
	class_addMethod(subclass,@selector(forwardInvocation:),myForwarder, method_getTypeEncoding(mf));	
	// hook up expect and stub
	IMP forwarder = [[[OCPartialMockForwardingHolder alloc] init]   methodForSelector: @selector(stub)];	
	mf = class_getInstanceMethod([OCPartialMockForwardingHolder class], @selector(expect));
	class_addMethod(subclass, @selector(expect), forwarder, method_getTypeEncoding(mf));
	mf = class_getInstanceMethod([OCPartialMockForwardingHolder class], @selector(stub));
	class_addMethod(subclass, @selector(stub), forwarder, method_getTypeEncoding(mf));
	
	objc_registerClassPair(subclass);
	object_setClass(anObject, subclass);

	[OCPartialMockObject shadowObject: anObject withMock: mockObject];
	return anObject;
}



+ (void) mockOrStubMethod: (SEL) selector forMock: (id) mock {
	Class subclass = [mock class];
	Method methodToForward = class_getInstanceMethod(subclass,selector);
	IMP forwarder = [mock methodForSelector:@selector(aMethodThatMustNotExist)];
	method_setImplementation(methodToForward,forwarder);
}



- (id)stub
{
	OCPartialMockRecorder *recorder = [[[OCPartialMockRecorder alloc] initWithSignatureResolver:self] autorelease];
	[recorders addObject:recorder];
	return recorder;
}


- (id)expect
{
	OCPartialMockRecorder *recorder = [self stub];
	[expectations addObject:recorder];
	return recorder;
}

- (id)initWithObject:(NSObject *)anObject
{
	[super initWithClass:[anObject class]];
	_realObject = [anObject retain];
	return self;
}

- (id) realObject {
	return _realObject;
}


- (void)dealloc
{
	[_realObject release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
//	overrides
//---------------------------------------------------------------------------------------

- (NSString *)description
{
	return [NSString stringWithFormat:@"OCPartialMockObject[%@]", NSStringFromClass(mockedClass)];
}

- (void)_handleUnRecordedInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:_realObject];
}

- (void) addRecorder:(OCMockRecorder *) recorder {
	[recorders addObject:recorder];
}

@end
