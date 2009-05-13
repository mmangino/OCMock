//
//  OCPartialMockRecorder.m
//  OCMock
//
//  Created by Michael Mangino on 5/13/09.
//  Copyright 2009 Elevated Rails, INC. All rights reserved.
//

#import "OCPartialMockRecorder.h"
#import "OCPartialMockObject.h"

@implementation OCPartialMockRecorder

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[OCPartialMockObject mockOrStubMethod: [anInvocation selector] forMock: [signatureResolver realObject]];
	[super forwardInvocation:anInvocation];

}


@end
