//
//  EDQueryView.m
//  Bob
//
//  Created by tisfeng on 2022/11/8.
//  Copyright © 2022 ripperhe. All rights reserved.
//

#import "EZQueryView.h"
#import "EZHoverButton.h"
#import "NSTextView+Height.h"
#import "EZWindowManager.h"
#import "NSView+EZGetViewController.h"

// static CGFloat kTextViewMiniHeight = 60;

@interface EZQueryView () <NSTextViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) EZButton *detectButton;

@property (nonatomic, assign) CGFloat textViewHeight;
@property (nonatomic, assign) CGFloat textViewMaxHeight;

@end

@implementation EZQueryView

#pragma mark - NSTextViewDelegate

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.textViewMiniHeight = 60;
        self.textViewMaxHeight = NSScreen.mainScreen.frame.size.height / 3; // 372
        self.textView.textContainerInset = NSMakeSize(8, 8);
        
        [self setup];
    }
    return self;
}

- (void)setup {
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    self.scrollView = scrollView;
    [self addSubview:scrollView];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.autohidesScrollers = YES;

    EZTextView *textView = [[EZTextView alloc] initWithFrame:scrollView.bounds];
    self.textView = textView;
    self.scrollView.documentView = textView;
    [textView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    textView.delegate = self;
    textView.textStorage.delegate = self;

    EZButton *detectButton = [[EZButton alloc] init];
    [self addSubview:detectButton];
    self.detectButton = detectButton;
    detectButton.hidden = YES;
    detectButton.cornerRadius = 10;
    detectButton.title = @"";

    [detectButton excuteLight:^(EZButton *detectButton) {
        NSColor *bgColor = [NSColor mm_colorWithHexString:@"#EAEAEA"];
        detectButton.backgroundColor = bgColor;
        detectButton.backgroundHoverColor = bgColor;
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#D1D1D1"];
    } drak:^(EZButton *button) {
        NSColor *bgColor = [NSColor mm_colorWithHexString:@"#313233"];
        detectButton.backgroundColor = bgColor;
        detectButton.backgroundHoverColor = bgColor;
        detectButton.backgroundHighlightColor = [NSColor mm_colorWithHexString:@"#535556"];
    }];

    mm_weakify(self);
    [detectButton setClickBlock:^(EZButton *_Nonnull button) {
        NSLog(@"detectButton");

        mm_strongify(self);
        if (self.detectActionBlock) {
            self.detectActionBlock(button);
        }
    }];

    detectButton.mas_key = @"detectButton";
}

- (void)updateConstraints {
    [self updateCustomLayout];

    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.inset(0);
        make.bottom.equalTo(self.audioButton.mas_top).offset(0);
        make.height.mas_greaterThanOrEqualTo(self.textViewMiniHeight).priorityLow();
        
//        make.height.mas_equalTo(self.textViewHeight);
    }];

    [self.detectButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.textCopyButton.mas_right).offset(8);
        make.centerY.equalTo(self.textCopyButton);
        make.height.mas_equalTo(20);
    }];

    [super updateConstraints];
}

- (void)updateCustomLayout {
    EZBaseQueryViewController *viewController = (EZBaseQueryViewController *)self.window.contentViewController;
    EZWindowType windowType = viewController.windowType;

    self.textViewHeight = [EZWindowFrameManager.shared getInputViewMiniHeight:windowType];
    
    switch (windowType) {
        case EZWindowTypeMini:
            self.textView.textContainerInset = NSMakeSize(4, 4);
            break;
        case EZWindowTypeMain:
        case EZWindowTypeFixed: {
            self.textView.textContainerInset = NSMakeSize(8, 8);
        }
        default:
            break;
    }
}

- (void)viewDidMoveToWindow {
//    NSLog(@"viewDidMoveToWindow: %@", self);
    
    [self scrollToTextViewBottom];
    
    [super viewDidMoveToWindow];
}

- (void)scrollToTextViewBottom {
//    NSLog(@"scroll to bottom: %@", self);
    
    // recover input focus
    [self.window makeFirstResponder:self.textView];
    
    // scroll to input view bottom
    NSScrollView *scrollView = self.scrollView;
    CGFloat height = scrollView.documentView.frame.size.height - scrollView.contentSize.height;
    [scrollView.contentView scrollToPoint:NSMakePoint(0, height)];
}


#pragma mark - Setter

- (void)setModel:(EZQueryModel *)model {
    _model = model;
    
    if (model.queryText) {
        self.textView.string = model.queryText;
    }
    
    Language fromLanguage = model.fromLanguage;
    if (fromLanguage != Language_auto) {
        self.detectLanguage =  LanguageDescFromEnum(fromLanguage);
    }
}

- (void)setQueryText:(NSString *)queryText {
    if (queryText) {
        self.textView.string = queryText;
    }
}

#pragma mark - Getter

- (NSString *)copiedText {
    return self.textView.string;
}

#pragma mark - Setter

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
        make.width.mas_equalTo(width + 8);
    }];
}


#pragma mark - NSTextViewDelegate

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

#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    NSString *text = textStorage.string;
    if (text.length == 0) {
        self.detectButton.hidden = YES;
    }
    

    CGFloat height = [self heightOfTextView];
    self.textViewHeight = height;
    
//    [self setNeedsUpdateConstraints:YES];

    [self.scrollView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(height);
    }];
    
    // cannot layout this, otherwise will crash
//    [self layoutSubtreeIfNeeded];
//    NSLog(@"self.frame: %@", @(self.frame));

    if (self.updateQueryTextBlock) {
        self.updateQueryTextBlock(text, height);
    }
}

- (CGFloat)heightOfTextView {
    CGFloat height = [self.textView getHeightWithWidth:self.width];
    //    NSLog(@"text: %@, height: %@", self.textView.string, @(height));

    if (height < self.textViewMiniHeight) {
        height = self.textViewMiniHeight;
    }
    if (height > self.textViewMaxHeight) {
        height = self.textViewMaxHeight;
        NSLog(@"reached maxHeight");
    }
    
    height = ceil(height);
//    NSLog(@"final height: %.1f", height);

    return height;
}

@end