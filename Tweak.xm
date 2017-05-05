@interface SpringBoard : NSObject
- (void)_simulateLockButtonPress;
@end

// LS Normal
@interface SBPagedScrollView : UIScrollView
@end

%hook SBPagedScrollView

- (void)_layoutPages {
    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGesture];
    [tapGesture release];

    %orig;
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"NORMAL LS/NC TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS notifications
@interface NCNotificationPriorityListViewController : UIViewController
@end

%hook NCNotificationPriorityListViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"LS NOTIF TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS media controls
@interface SBDashBoardMediaControlsViewController : UIViewController
@end

%hook SBDashBoardMediaControlsViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"LS MEDIA CTRLS TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS Artwork
// Add directly to artworkView doesn't work. Instead, create a new view and add that to artwork

@interface SBDashBoardMediaArtworkViewController : UIViewController
- (void)addGestureView;
@end

@interface MPUNowPlayingArtworkView : UIView
@end

static MPUNowPlayingArtworkView *LSArtworkView;
static UIView *gestureView;
static SBDashBoardMediaArtworkViewController *artworkViewController;

%hook MPUNowPlayingArtworkView

- (id)initWithFrame:(CGRect)frame {
    // We only want the first that gets initalized (LS)
    return LSArtworkView ? %orig : LSArtworkView = %orig;
}

- (void)setFrame:(CGRect)frame {
    %orig;

    if (self == LSArtworkView && !gestureView) {
        // If this would've gone directly to artworkViewController's viewDidLoad, LSArtworkView's frame is 0,0,0,0 by that time.
        [artworkViewController addGestureView];
    }
}

%end

%hook SBDashBoardMediaArtworkViewController

- (id)init {
    return artworkViewController = %orig;
}

%new
- (void)addGestureView {
    gestureView = [[UIView alloc] initWithFrame:LSArtworkView.frame];
    [gestureView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.01]];

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [gestureView addGestureRecognizer:tapGesture];
    [tapGesture release];

    [self.view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"LS ARTWORK TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS Passcode screen
@interface SBDashBoardModalPresentationViewController : UIViewController
@end

%hook SBDashBoardModalPresentationViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"LS PASSCODE TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// Home screen
@interface SBHomeScreenViewController : UIViewController
@end

%hook SBHomeScreenViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];

    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        HBLogDebug(@"HOME TAP");
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end
