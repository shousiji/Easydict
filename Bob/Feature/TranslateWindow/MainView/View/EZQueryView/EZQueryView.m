//
//  EDQueryView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryView.h"
#import "EZHoverButton.h"

@interface EZQueryView () <NSTextViewDelegate>

@property (nonatomic, strong) NSScrollView *scrollView;

@property (nonatomic, strong) NSButton *detectButton;

@end

@implementation EZQueryView

@synthesize copiedText = _copiedText;

#pragma mark - NSTextViewDelegate

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.copiedText = @"";
    
    self.scrollView = [NSScrollView mm_make:^(NSScrollView *_Nonnull scrollView) {
        [self addSubview:scrollView];
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;
        scrollView.autohidesScrollers = YES;
        self.textView = [[TextView alloc] initWithFrame:self.bounds];
        self.textView = [TextView mm_make:^(TextView *textView) {
            [textView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
            textView.delegate = self;
        }];
        scrollView.documentView = self.textView;
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.inset(0);
//            make.bottom.inset(kVerticalMargin);
            make.bottom.equalTo(self.audioButton.mas_top).offset(-5);
        }];
    }];
    
    
    NSButton *detectButton = [[NSButton alloc] init];
    detectButton.hidden = YES;
    detectButton.bordered = YES;
    detectButton.bezelStyle = NSBezelStyleInline;
    [detectButton setButtonType:NSButtonTypeMomentaryChange];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    
    [detectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textCopyButton.mas_right).offset(8);
        make.centerY.equalTo(self.textCopyButton);
        make.height.mas_equalTo(20);
    }];
    
    mm_weakify(self)
    [detectButton setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *_Nonnull(id _Nullable input) {
        NSLog(@"detectActionBlock");

        mm_strongify(self)
        if (self.detectActionBlock) {
            self.detectActionBlock(input);
        }
        return RACSignal.empty;
    }]];
    
    detectButton.mas_key = @"detectButton";
}

- (NSString *)copiedText {
    return self.textView.string;
}

- (void)setCopiedText:(NSString *)queryText {
    _copiedText = queryText ?: @"";
    
    self.textView.string = _copiedText;
}

- (void)setDetectLanguage:(NSString *)detectLanguage {
    _detectLanguage = detectLanguage;
    
    NSString *title = @"识别为 ";
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attrTitle addAttributes:@{
        NSForegroundColorAttributeName : NSColor.grayColor,
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                       range:NSMakeRange(0, attrTitle.length)];
    
    
    NSMutableAttributedString *detectAttrTitle = [[NSMutableAttributedString alloc] initWithString:detectLanguage];
    [detectAttrTitle addAttributes:@{
        NSForegroundColorAttributeName : [NSColor mm_colorWithHexString:@"#007AFF"],
        NSFontAttributeName : [NSFont systemFontOfSize:10],
    }
                             range:NSMakeRange(0, detectAttrTitle.length)];
    
    [attrTitle appendAttributedString:detectAttrTitle];
    
    CGFloat width = [attrTitle mm_getTextWidth];
    self.detectButton.hidden = NO;
    self.detectButton.attributedTitle = attrTitle;
    [self.detectButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width + 10);
    }];
    
    [self layoutSubtreeIfNeeded];
}


- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        NSEventModifierFlags flags = NSApplication.sharedApplication.currentEvent.modifierFlags;
        if (flags & NSEventModifierFlagShift) {
            return NO;
        } else {
            if (self.enterActionBlock) {
                NSLog(@"enterActionBlock");
                self.enterActionBlock(self.copiedText);
            }
            return YES;
        }
    }
    return NO;
}

@end