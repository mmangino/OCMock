//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface NSMethodSignature(PrivateAPI)

+ (id)signatureWithObjCTypes:(const char *)types;

@end
