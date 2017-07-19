#import "EmojiHUD.h"
#import "../EmojiLibrary/PSEmojiUtilities.h"
#import <substrate.h>

@implementation EmojiHUD

@synthesize showing = _showing;

+ (CGRect)hudFrame {
    CGFloat width = IS_IPAD ? 300 : 260;
    CGFloat height = IS_IPAD ? 55 : 40;
    CGRect bounds = UIScreen.mainScreen.bounds;
    CGFloat x = (bounds.size.width - width) / 2;
    CGFloat y = (bounds.size.height - height) / 2;
    if (IS_IPAD && bounds.size.height > 768)
        y += 140;
    return CGRectMake(x, y, width, height);
}

+ (UIView *)hudWindow {
    return UIKeyboard.activeKeyboard.window;
}

+ (EmojiHUD *)sharedInstance {
    static EmojiHUD *sharedHUD = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHUD = [[self alloc] init];
        sharedHUD.frame = [self hudFrame];
        sharedHUD.hidden = YES;
        sharedHUD.showing = NO;
        [[self hudWindow] addSubview:sharedHUD];
    });
    return sharedHUD;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.layer.cornerRadius = 12;
    }
    return self;
}

- (void)clearViews {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.subviews makeObjectsPerformSelector:@selector(release)];
}

- (void)show:(BOOL)show {
    self.showing = show;
    self.hidden = !show;
    if (show)
        self.frame = [[self class] hudFrame];
}

- (void)show {
    [self show:YES];
}

- (void)emojiUsed:(UIKeyboardEmoji *)emoji {
    if (!emoji || !emoji.emojiString.length)
        return;
    UIKeyboardLayoutEmoji *layout = (UIKeyboardLayoutEmoji *)[NSClassFromString(@"UIKeyboardLayoutEmoji") emojiLayout];
    [layout emojiSelected:emoji];
    [self hide];
}

- (NSArray <NSString *> *)variantsForEmoji:(NSString *)emojiString {
    return [PSEmojiUtilities skinToneVariants:emojiString isSkin:YES];
}

- (UIKeyboardEmoji *)emojiFromVariant:(NSInteger)variant {
    return [PSEmojiUtilities emojiWithString:[PSEmojiUtilities skinToneVariant:self->_emojiString baseFirst:nil base:nil skin:[[PSEmojiUtilities skinModifiers] objectAtIndex:variant - 1]]];
}

- (void)emojiUsedInVariant:(NSInteger)variant {
    UIKeyboardEmoji *emoji = [self emojiFromVariant:variant];
    [self emojiUsed:emoji];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:touch.view];
    CGFloat totalWidth = self.frame.size.width;
    CGFloat section = totalWidth / 5.0;
    CGFloat vf = touchLocation.x / section;
    #if __LP64__
    NSInteger variant = (NSInteger)ceil(vf);
    #else
    NSInteger variant = (NSInteger)ceilf(vf);
    #endif
    [self emojiUsedInVariant:variant];
}

- (void)showWithEmojiView:(UIKeyboardEmojiView *)emojiView {
    [self clearViews];
    [self show];
    NSString *emojiString = emojiView.emoji.emojiString;
    if (emojiString) {
        self->_emojiString = emojiString;
        CGRect hudFrame = self.frame;
        CGFloat totalWidth = hudFrame.size.width;
        CGFloat totalHeight = hudFrame.size.height;
        CGFloat emojiWidth = emojiView.frame.size.width;
        CGFloat emojiHeight = emojiView.frame.size.height;
        CGRect frame = emojiView.frame;
        CGFloat gap = (totalWidth - (5 * emojiWidth)) / 6;
        frame = CGRectMake(gap, (totalHeight - emojiHeight) / 2, emojiWidth, emojiHeight);
        NSArray <NSString *> *variants = [self variantsForEmoji:emojiString];
        for (NSString *variant in variants) {
            UIKeyboardEmojiView *diverse = [NSClassFromString(@"UIKeyboardEmojiView") emojiViewForEmoji:[PSEmojiUtilities emojiWithString:variant] withFrame:frame];
            [self addSubview:diverse];
            diverse.userInteractionEnabled = NO;
            frame = CGRectMake(frame.origin.x + gap + emojiWidth, frame.origin.y, frame.size.width, frame.size.height);
        }
    }
}

- (void)hide {
    if (self.showing)
        [self show:NO];
}

@end
