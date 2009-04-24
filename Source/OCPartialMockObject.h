//---------------------------------------------------------------------------------------
//  $Id: OCPartialMockObject.h $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "OCClassMockObject.h"


@interface OCPartialMockObject : OCClassMockObject 
{
	NSObject	*realObject;
}

- (id)initWithObject:(NSObject *)anObject;

@end
