#import "../SettingsKeys.h"
#import <Preferences/Preferences.h>
#import "../../TwitterStuff/Prompt.h"
#import <notify.h>

@interface PLGRootListController : PSListController
@end

@implementation PLGRootListController

- (NSArray *)specifiers {
    if (!_specifiers)
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];

    return _specifiers;
}

- (void)loadView {
    [super loadView];
    presentFollowAlert(kPrefPath, self);
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

    NSString *key = [specifier propertyForKey:@"key"];
    if (!preferences[key])
        return specifier.properties[@"default"];

    return preferences[key];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *prefPath = kPrefPath;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
    if (!dictionary)
        dictionary = [NSMutableDictionary dictionary];

    NSDictionary *properties = specifier.properties;

    [dictionary setObject:value forKey:properties[@"key"]];
    [dictionary writeToFile:prefPath atomically:YES];

    notify_post(kSettingsChanged);
}

- (void)followTwitter {
    openTwitter();
}

- (void)discordServer {
    openURL([NSURL URLWithString:@"https://discord.gg/7F3fSnH"]);
}

- (void)donate {
    openURL([NSURL URLWithString:@"https://paypal.me/aNosskirneh"]);
}

- (void)sendEmail {
    openURL([NSURL URLWithString:@"mailto:andreaskhenriksson@gmail.com?subject=ProperLockGestures"]);
}

- (void)sourceCode {
    openURL([NSURL URLWithString:@"https://github.com/Nosskirneh/ProperLockGestures"]);
}

@end


@interface PLGHeaderCell : PSTableCell
@end

@implementation PLGHeaderCell {
    UILabel *_headerLabel;
    UILabel *_subheaderLabel;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    if (self) {
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:24];

        _headerLabel = [[UILabel alloc] init];
        [_headerLabel setText:@"ProperLockGestures"];
        [_headerLabel setFont:font];

        _subheaderLabel = [[UILabel alloc] init];
        [_subheaderLabel setText:@"by Andreas Henriksson"];
        [_subheaderLabel setTextColor:UIColor.grayColor];
        [_subheaderLabel setFont:[font fontWithSize:17]];

        [self addSubview:_headerLabel];
        [self addSubview:_subheaderLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [_headerLabel sizeToFit];
    [_subheaderLabel sizeToFit];

    CGRect frame = _headerLabel.frame;
    frame.origin.y = 20;
    frame.origin.x = self.frame.size.width / 2 - _headerLabel.frame.size.width / 2;
    _headerLabel.frame = frame;

    frame.origin.y += _headerLabel.frame.size.height;
    frame.origin.x = self.frame.size.width / 2 - _subheaderLabel.frame.size.width / 2;
    _subheaderLabel.frame = frame;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    // Return a custom cell height.
    return 80;
}

@end

// Colorful UISwitches
@interface PSSwitchTableCell : PSControlTableCell
- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier;
@end

@interface PLGSwitchTableCell : PSSwitchTableCell
@end

@implementation PLGSwitchTableCell

- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];
    if (self)
        [((UISwitch *)[self control]) setOnTintColor:[UIColor colorWithRed:0.00 green:0.48 blue:1.00 alpha:1.0]];
    return self;
}

@end
