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
- (void) verify;
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
- (void) verify {
	OCMockObject *shadow = [_OCPartialMockShadowObjects objectForKey:[NSString stringWithCString:object_getClassName(self)]];
	[shadow verify];
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
+(void) forwardMethodToHolder:(SEL) selector forClass:(Class) c
{
	OCPartialMockForwardingHolder * holder = [[OCPartialMockForwardingHolder alloc] init];
	IMP implementation = [ holder methodForSelector: selector];	
	Method mf = class_getInstanceMethod([OCPartialMockForwardingHolder class], selector);
	class_addMethod(c,selector, implementation, method_getTypeEncoding(mf));
	[holder release];
}

+ (id)partialMockWithObject:(NSObject *)anObject 
{

	// create the custom subclass and a mock
	NSString *objectIdentifier = [NSString stringWithFormat:@"Mock%d%s",[OCPartialMockObject nextSequence],class_getName([anObject class])];
	Class subclass = objc_allocateClassPair([anObject class], [objectIdentifier cStringUsingEncoding:NSASCIIStringEncoding], 0);
	id mockObject = [[OCPartialMockObject alloc] initWithObject:anObject];

	// Hook up the forwarder
	IMP myForwarder = class_getMethodImplementation([OCPartialMockForwardingHolder class],@selector(forwardToShadow:));
	Method mf = class_getInstanceMethod([mockObject class], @selector(forwardToShadow:));
	class_addMethod(subclass,@selector(forwardInvocation:),myForwarder, method_getTypeEncoding(mf));	
	
	// hook up expect, stub and verify
	[OCPartialMockObject forwardMethodToHolder:@selector(expect) forClass:subclass];
	[OCPartialMockObject forwardMethodToHolder:@selector(stub) forClass:subclass];
	[OCPartialMockObject forwardMethodToHolder:@selector(verify) forClass:subclass];
	
	// register the class and convert the object to our new class
	objc_registerClassPair(subclass);
	object_setClass(anObject, subclass);

	//register the shadow
	[OCPartialMockObject shadowObject: anObject withMock: mockObject];
	return anObject;
}



+ (void) mockOrStubMethod: (SEL) selector forMock: (id) mock 
{
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
