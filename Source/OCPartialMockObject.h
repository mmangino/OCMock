//---------------------------------------------------------------------------------------
//  $Id: OCPartialMockObject.h $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCClassMockObject.h"


@interface OCPartialMockObject : OCClassMockObject 
{
	NSObject	*_realObject;
}

- (id) realObject;
- (id)initWithObject:(NSObject *)anObject;
+ (id)partialMockWithObject:(NSObject *)anObject;
+ (void) mockOrStubMethod: (SEL) selector forMock: (id) mock;
@end
