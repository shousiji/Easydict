//
//  EZLinkButton.h
//  Easydict
//
//  Created by tisfeng on 2022/12/6.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZHoverButton.h"

NS_ASSUME_NONNULL_BEGIN

// TODO: need to optimize, similar to EZBlueTextButton.
@interface EZLinkButton : EZButton

@property (nonatomic, copy, nullable) NSString *link;

- (void)openLink;

@end

NS_ASSUME_NONNULL_END
