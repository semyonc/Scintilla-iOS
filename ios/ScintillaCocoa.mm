
/**
 * Scintilla source code edit control
 * ScintillaCocoa.mm - Cocoa subclass of ScintillaBase
 * 
 * Written by Mike Lischke <mlischke@sun.com>
 *
 * Loosely based on ScintillaMacOSX.cxx.
 * Copyright 2003 by Evan Jones <ejones@uwaterloo.ca>
 * Based on ScintillaGTK.cxx Copyright 1998-2002 by Neil Hodgson <neilh@scintilla.org>
 * The License.txt file describes the conditions under which this software may be distributed.
  *
 * Copyright (c) 2009, 2010 Sun Microsystems, Inc. All rights reserved.
 * This file is dual licensed under LGPL v2.1 and the Scintilla license (http://www.scintilla.org/License.txt).
 */

#import <UIKit/UIKit.h>
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
#import <QuartzCore/CAGradientLayer.h>
#endif
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>

#import "Platform.h"
#import "ScintillaView.h"
#import "ScintillaCocoa.h"
#import "PlatCocoa.h"

using namespace Scintilla;

NSString* ScintillaRecPboardType = @"com.scintilla.utf16-plain-text.rectangular";

//--------------------------------------------------------------------------------------------------

// Define keyboard shortcuts (equivalents) the Mac way.
#define SCI_CMD ( SCI_CTRL)
#define SCI_SCMD ( SCI_CMD | SCI_SHIFT)
#define SCI_SMETA ( SCI_META | SCI_SHIFT)

static const KeyToCommand macMapDefault[] =
{
  // OS X specific
  {SCK_DOWN,      SCI_CTRL,   SCI_DOCUMENTEND},
  {SCK_DOWN,      SCI_CSHIFT, SCI_DOCUMENTENDEXTEND},
  {SCK_UP,        SCI_CTRL,   SCI_DOCUMENTSTART},
  {SCK_UP,        SCI_CSHIFT, SCI_DOCUMENTSTARTEXTEND},
  {SCK_LEFT,      SCI_CTRL,   SCI_VCHOME},
  {SCK_LEFT,      SCI_CSHIFT, SCI_VCHOMEEXTEND},
  {SCK_RIGHT,     SCI_CTRL,   SCI_LINEEND},
  {SCK_RIGHT,     SCI_CSHIFT, SCI_LINEENDEXTEND},

  // Similar to Windows and GTK+
  // Where equivalent clashes with OS X standard, use Meta instead
  {SCK_DOWN,      SCI_NORM,   SCI_LINEDOWN},
  {SCK_DOWN,      SCI_SHIFT,  SCI_LINEDOWNEXTEND},
  {SCK_DOWN,      SCI_META,   SCI_LINESCROLLDOWN},
  {SCK_DOWN,      SCI_ASHIFT, SCI_LINEDOWNRECTEXTEND},
  {SCK_UP,        SCI_NORM,   SCI_LINEUP},
  {SCK_UP,        SCI_SHIFT,  SCI_LINEUPEXTEND},
  {SCK_UP,        SCI_META,   SCI_LINESCROLLUP},
  {SCK_UP,        SCI_ASHIFT, SCI_LINEUPRECTEXTEND},
  {'[',           SCI_CTRL,   SCI_PARAUP},
  {'[',           SCI_CSHIFT, SCI_PARAUPEXTEND},
  {']',           SCI_CTRL,   SCI_PARADOWN},
  {']',           SCI_CSHIFT, SCI_PARADOWNEXTEND},
  {SCK_LEFT,      SCI_NORM,   SCI_CHARLEFT},
  {SCK_LEFT,      SCI_SHIFT,  SCI_CHARLEFTEXTEND},
  {SCK_LEFT,      SCI_ALT,    SCI_WORDLEFT},
  {SCK_LEFT,      SCI_META,   SCI_WORDLEFT},
  {SCK_LEFT,      SCI_SMETA,  SCI_WORDLEFTEXTEND},
  {SCK_LEFT,      SCI_ASHIFT, SCI_CHARLEFTRECTEXTEND},
  {SCK_RIGHT,     SCI_NORM,   SCI_CHARRIGHT},
  {SCK_RIGHT,     SCI_SHIFT,  SCI_CHARRIGHTEXTEND},
  {SCK_RIGHT,     SCI_ALT,    SCI_WORDRIGHT},
  {SCK_RIGHT,     SCI_META,   SCI_WORDRIGHT},
  {SCK_RIGHT,     SCI_SMETA,  SCI_WORDRIGHTEXTEND},
  {SCK_RIGHT,     SCI_ASHIFT, SCI_CHARRIGHTRECTEXTEND},
  {'/',           SCI_CTRL,   SCI_WORDPARTLEFT},
  {'/',           SCI_CSHIFT, SCI_WORDPARTLEFTEXTEND},
  {'\\',          SCI_CTRL,   SCI_WORDPARTRIGHT},
  {'\\',          SCI_CSHIFT, SCI_WORDPARTRIGHTEXTEND},
  {SCK_HOME,      SCI_NORM,   SCI_VCHOME},
  {SCK_HOME,      SCI_SHIFT,  SCI_VCHOMEEXTEND},
  {SCK_HOME,      SCI_CTRL,   SCI_DOCUMENTSTART},
  {SCK_HOME,      SCI_CSHIFT, SCI_DOCUMENTSTARTEXTEND},
  {SCK_HOME,      SCI_ALT,    SCI_HOMEDISPLAY},
  {SCK_HOME,      SCI_ASHIFT, SCI_VCHOMERECTEXTEND},
  {SCK_END,       SCI_NORM,   SCI_LINEEND},
  {SCK_END,       SCI_SHIFT,  SCI_LINEENDEXTEND},
  {SCK_END,       SCI_CTRL,   SCI_DOCUMENTEND},
  {SCK_END,       SCI_CSHIFT, SCI_DOCUMENTENDEXTEND},
  {SCK_END,       SCI_ALT,    SCI_LINEENDDISPLAY},
  {SCK_END,       SCI_ASHIFT, SCI_LINEENDRECTEXTEND},
  {SCK_PRIOR,     SCI_NORM,   SCI_PAGEUP},
  {SCK_PRIOR,     SCI_SHIFT,  SCI_PAGEUPEXTEND},
  {SCK_PRIOR,     SCI_ASHIFT, SCI_PAGEUPRECTEXTEND},
  {SCK_NEXT,      SCI_NORM,   SCI_PAGEDOWN},
  {SCK_NEXT,      SCI_SHIFT,  SCI_PAGEDOWNEXTEND},
  {SCK_NEXT,      SCI_ASHIFT, SCI_PAGEDOWNRECTEXTEND},
  {SCK_DELETE,    SCI_NORM,   SCI_CLEAR},
  {SCK_DELETE,    SCI_SHIFT,  SCI_CUT},
  {SCK_DELETE,    SCI_CTRL,   SCI_DELWORDRIGHT},
  {SCK_DELETE,    SCI_CSHIFT, SCI_DELLINERIGHT},
  {SCK_INSERT,    SCI_NORM,   SCI_EDITTOGGLEOVERTYPE},
  {SCK_INSERT,    SCI_SHIFT,  SCI_PASTE},
  {SCK_INSERT,    SCI_CTRL,   SCI_COPY},
  {SCK_ESCAPE,    SCI_NORM,   SCI_CANCEL},
  {SCK_BACK,      SCI_NORM,   SCI_DELETEBACK},
  {SCK_BACK,      SCI_SHIFT,  SCI_DELETEBACK},
  {SCK_BACK,      SCI_CTRL,   SCI_DELWORDLEFT},
  {SCK_BACK,      SCI_ALT,    SCI_DELWORDLEFT},
  {SCK_BACK,      SCI_CSHIFT, SCI_DELLINELEFT},
  {'z',           SCI_CMD,    SCI_UNDO},
  {'z',           SCI_SCMD,   SCI_REDO},
  {'x',           SCI_CMD,    SCI_CUT},
  {'c',           SCI_CMD,    SCI_COPY},
  {'v',           SCI_CMD,    SCI_PASTE},
  {'a',           SCI_CMD,    SCI_SELECTALL},
  {SCK_TAB,       SCI_NORM,   SCI_TAB},
  {SCK_TAB,       SCI_SHIFT,  SCI_BACKTAB},
  {SCK_RETURN,    SCI_NORM,   SCI_NEWLINE},
  {SCK_RETURN,    SCI_SHIFT,  SCI_NEWLINE},
  {SCK_ADD,       SCI_CMD,    SCI_ZOOMIN},
  {SCK_SUBTRACT,  SCI_CMD,    SCI_ZOOMOUT},
  {SCK_DIVIDE,    SCI_CMD,    SCI_SETZOOM},
  {'l',           SCI_CMD,    SCI_LINECUT},
  {'l',           SCI_CSHIFT, SCI_LINEDELETE},
  {'t',           SCI_CSHIFT, SCI_LINECOPY},
  {'t',           SCI_CTRL,   SCI_LINETRANSPOSE},
  {'d',           SCI_CTRL,   SCI_SELECTIONDUPLICATE},
  {'u',           SCI_CTRL,   SCI_LOWERCASE},
  {'u',           SCI_CSHIFT, SCI_UPPERCASE},
  {0, 0, 0},
};

//--------------------------------------------------------------------------------------------------

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

// Only implement FindHighlightLayer on OS X 10.6+

/**
 * Class to display the animated gold roundrect used on OS X for matches.
 */
@interface FindHighlightLayer : CAGradientLayer
{
@private
	NSString *sFind;
	int positionFind;
	BOOL retaining;
	CGFloat widthText;
	CGFloat heightLine;
	NSString *sFont;
	CGFloat fontSize;
}

@property (copy) NSString *sFind;
@property (assign) int positionFind;
@property (assign) BOOL retaining;
@property (assign) CGFloat widthText;
@property (assign) CGFloat heightLine;
@property (copy) NSString *sFont;
@property (assign) CGFloat fontSize;

- (void) animateMatch: (CGPoint)ptText bounce:(BOOL)bounce;
- (void) hideMatch;

@end

//--------------------------------------------------------------------------------------------------

@implementation FindHighlightLayer

@synthesize sFind, positionFind, retaining, widthText, heightLine, sFont, fontSize;

-(id) init {
	if (self = [super init]) {
		[self setNeedsDisplayOnBoundsChange: YES];
        
        self.contentsScale = [[UIScreen mainScreen] scale]; /* semyonc */
        
        // A gold to slightly redder gradient to match other applications
        CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
        const CGFloat colorRef1[] = { 1.0, 1.0, 0, 1.0, 1.0 };
        const CGFloat colorRef2[] = { 1.0, 0.8, 0, 1.0 };
        CGColorRef colGold = CGColorCreate(rgb, colorRef1);
        CGColorRef colGoldRed = CGColorCreate(rgb, colorRef2);
		self.colors = [NSArray arrayWithObjects:(id)colGoldRed, (id)colGold, nil];
		CGColorRelease(colGoldRed);
		CGColorRelease(colGold);
        
        CGColorSpaceRelease(rgb);
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
        const CGFloat components[] = {0.756f, 0.5f};
        CGColorRef colGreyBorder = CGColorCreate(colorspace, components);
		self.borderColor = colGreyBorder;
		CGColorRelease(colGreyBorder);
        CGColorSpaceRelease(colorspace);

		self.borderWidth = 1.0;
		self.cornerRadius = 5.0f;
		self.shadowRadius = 1.0f;
		self.shadowOpacity = 0.9f;
		self.shadowOffset = CGSizeMake(0.0f, -2.0f);
		self.anchorPoint = CGPointMake(0.5, 0.5);
	}
	return self;
	
}

const CGFloat paddingHighlightX = 4;
const CGFloat paddingHighlightY = 2;

-(void) drawInContext:(CGContextRef)context {
	if (!sFind || !sFont)
		return;
	
	CFStringRef str = CFStringRef(sFind);
	
	CFMutableDictionaryRef styleDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 2,
								     &kCFTypeDictionaryKeyCallBacks, 
								     &kCFTypeDictionaryValueCallBacks);
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    const CGFloat colorRef[] = { 0.0, 0.0, 0.0, 1.0 };
    CGColorRef color = CGColorCreate(rgb, colorRef);
    CGColorSpaceRelease(rgb);
    
	CFDictionarySetValue(styleDict, kCTForegroundColorAttributeName, color);
	CTFontRef fontRef = ::CTFontCreateWithName((CFStringRef)sFont, fontSize, NULL);
	CFDictionaryAddValue(styleDict, kCTFontAttributeName, fontRef);
	
	CFAttributedStringRef attrString = ::CFAttributedStringCreate(NULL, str, styleDict);
	CTLineRef textLine = ::CTLineCreateWithAttributedString(attrString);
	// Indent from corner of bounds
	CGContextSetTextPosition(context, paddingHighlightX, 3 + paddingHighlightY);
	CTLineDraw(textLine, context);
	
	CFRelease(textLine);
	CFRelease(attrString);
	CFRelease(fontRef);
	CGColorRelease(color);
	CFRelease(styleDict);
}

- (void) animateMatch: (CGPoint)ptText bounce:(BOOL)bounce {
	if (!self.sFind || ![self.sFind length]) {
		[self hideMatch];
		return;
	}

	CGFloat width = self.widthText + paddingHighlightX * 2;
	CGFloat height = self.heightLine + paddingHighlightY * 2;

	CGFloat flipper = self.geometryFlipped ? -1.0 : 1.0;

	// Adjust for padding
	ptText.x -= paddingHighlightX;
	ptText.y += flipper * paddingHighlightY;

	// Shift point to centre as expanding about centre
	ptText.x += width / 2.0;
	ptText.y -= flipper * height / 2.0;

	[CATransaction begin];
	[CATransaction setValue:[NSNumber numberWithFloat:0.0] forKey:kCATransactionAnimationDuration];
	self.bounds = CGRectMake(0,0, width, height);
	self.position = ptText;
	if (bounce) {
		// Do not reset visibility when just moving
		self.hidden = NO;
		self.opacity = 1.0;
	}
	[self setNeedsDisplay];
	[CATransaction commit];
	
	if (bounce) {
		CABasicAnimation *animBounce = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
		animBounce.duration = 0.15;
		animBounce.autoreverses = YES;
		animBounce.removedOnCompletion = NO;
		animBounce.fromValue = [NSNumber numberWithFloat: 1.0];
		animBounce.toValue = [NSNumber numberWithFloat: 1.25];
		
		if (self.retaining) {
			
			[self addAnimation: animBounce forKey:@"animateFound"];
			
		} else {
			
			CABasicAnimation *animFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
			animFade.duration = 0.1;
			animFade.beginTime = 0.4;
			animFade.removedOnCompletion = NO;
			animFade.fromValue = [NSNumber numberWithFloat: 1.0];
			animFade.toValue = [NSNumber numberWithFloat: 0.0];
			
			CAAnimationGroup *group = [CAAnimationGroup animation];
			[group setDuration:0.5];
			group.removedOnCompletion = NO;
			group.fillMode = kCAFillModeForwards;
			[group setAnimations:[NSArray arrayWithObjects:animBounce, animFade, nil]];
			
			[self addAnimation:group forKey:@"animateFound"];
		}
	}
}

- (void) hideMatch {
	self.sFind = @"";
	self.positionFind = INVALID_POSITION;
	self.hidden = YES;
}

@end

#endif

//--------------------------------------------------------------------------------------------------

@implementation TimerTarget

- (id) init: (void*) target
{
  self = [super init];
  if (self != nil)
  {
    mTarget = target;

    // Get the default notification queue for the thread which created the instance (usually the
    // main thread). We need that later for idle event processing.
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter]; 
    notificationQueue = [[NSNotificationQueue alloc] initWithNotificationCenter: center];
    [center addObserver: self selector: @selector(idleTriggered:) name: @"Idle" object: nil]; 
  }
  return self;
}

//--------------------------------------------------------------------------------------------------

- (void) dealloc
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [notificationQueue release];
  [super dealloc];
}

//--------------------------------------------------------------------------------------------------

/**
 * Method called by a timer installed by ScintillaCocoa. This two step approach is needed because
 * a native Obj-C class is required as target for the timer.
 */
- (void) timerFired: (NSTimer*) timer
{
  reinterpret_cast<ScintillaCocoa*>(mTarget)->TimerFired(timer);
}

//--------------------------------------------------------------------------------------------------

/**
 * Another timer callback for the idle timer.
 */
- (void) idleTimerFired: (NSTimer*) timer
{
#pragma unused(timer)
  // Idle timer event.
  // Post a new idle notification, which gets executed when the run loop is idle.
  // Since we are coalescing on name and sender there will always be only one actual notification
  // even for multiple requests.
  NSNotification *notification = [NSNotification notificationWithName: @"Idle" object: self]; 
  [notificationQueue enqueueNotification: notification
                            postingStyle: NSPostWhenIdle
                            coalesceMask: (NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                                forModes: nil]; 
}

//--------------------------------------------------------------------------------------------------

/**
 * Another step for idle events. The timer (for idle events) simply requests a notification on
 * idle time. Only when this notification is send we actually call back the editor.
 */
- (void) idleTriggered: (NSNotification*) notification
{
#pragma unused(notification)
  reinterpret_cast<ScintillaCocoa*>(mTarget)->IdleTimerFired();
}

@end

//----------------- ScintillaCocoa -----------------------------------------------------------------

ScintillaCocoa::ScintillaCocoa(SCIContentView* view, SCIMarginView* viewMargin)
{
  vs.marginInside = true;
  wMain = view; // Don't retain since we're owned by view, which would cause a cycle
  wMargin = viewMargin;
  timerTarget = [[TimerTarget alloc] init: this];
  lastMouseEvent = NULL;
  delegate = NULL;
  notifyObj = NULL;
  notifyProc = NULL;
  capturedMouse = false;
  enteredSetScrollingSize = false;
  scrollSpeed = 1;
  scrollTicks = 2000;
  tickTimer = NULL;
  idleTimer = NULL;
  observer = NULL;
  layerFindIndicator = NULL;
  Initialise();
}

//--------------------------------------------------------------------------------------------------

ScintillaCocoa::~ScintillaCocoa()
{
  Finalise();
  [timerTarget release];
}

//--------------------------------------------------------------------------------------------------

/**
 * Core initialization of the control. Everything that needs to be set up happens here.
 */
void ScintillaCocoa::Initialise() 
{
  Scintilla_LinkLexers();
  
  // Tell Scintilla not to buffer: Quartz buffers drawing for us.
  WndProc(SCI_SETBUFFEREDDRAW, 0, 0);
  
  // We are working with Unicode exclusively.
  WndProc(SCI_SETCODEPAGE, SC_CP_UTF8, 0);

  // Add Mac specific key bindings.
  for (int i = 0; macMapDefault[i].key; i++) 
    kmap.AssignCmdKey(macMapDefault[i].key, macMapDefault[i].modifiers, macMapDefault[i].msg);
  
}

//--------------------------------------------------------------------------------------------------

/**
 * We need some clean up. Do it here.
 */
void ScintillaCocoa::Finalise()
{
  ObserverRemove();
  SetTicking(false);
  ScintillaBase::Finalise();
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::UpdateObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
  ScintillaCocoa* sci = reinterpret_cast<ScintillaCocoa*>(info);
  sci->IdleWork();
}

//--------------------------------------------------------------------------------------------------

/**
 * Add an observer to the run loop to perform styling as high-priority idle task.
 */

void ScintillaCocoa::ObserverAdd() {
  if (!observer) {
    CFRunLoopObserverContext context;
    context.version = 0;
    context.info = this;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;

    CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
    observer = CFRunLoopObserverCreate(NULL, kCFRunLoopEntry | kCFRunLoopBeforeWaiting,
      true, 0, UpdateObserver, &context);
    CFRunLoopAddObserver(mainRunLoop, observer, kCFRunLoopCommonModes);
  }
}

//--------------------------------------------------------------------------------------------------

/**
 * Remove the run loop observer.
 */
void ScintillaCocoa::ObserverRemove() {
  if (observer) {
    CFRunLoopRef mainRunLoop = CFRunLoopGetMain();
    CFRunLoopRemoveObserver(mainRunLoop, observer, kCFRunLoopCommonModes);
    CFRelease(observer);
  }
  observer = NULL;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::IdleWork() {
  Editor::IdleWork();
  ObserverRemove();
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::QueueIdleWork(WorkNeeded::workItems items, int upTo) {
  Editor::QueueIdleWork(items, upTo);
  ObserverAdd();
}

//--------------------------------------------------------------------------------------------------

/**
 * Convert a core foundation string into an array of bytes in a particular encoding
 */

static char *EncodedBytes(CFStringRef cfsRef, CFStringEncoding encoding) {
    CFRange rangeAll = {0, CFStringGetLength(cfsRef)};
    CFIndex usedLen = 0;
    CFStringGetBytes(cfsRef, rangeAll, encoding, '?',
                     false, NULL, 0, &usedLen);
    
    char *buffer = new char[usedLen+1];
    CFStringGetBytes(cfsRef, rangeAll, encoding, '?',
                     false, (UInt8 *)buffer,usedLen, NULL);
    buffer[usedLen] = '\0';
    return buffer;
}

//--------------------------------------------------------------------------------------------------

/**
 * Case folders.
 */

class CaseFolderDBCS : public CaseFolderTable {
	CFStringEncoding encoding;
public:
	CaseFolderDBCS(CFStringEncoding encoding_) : encoding(encoding_) {
		StandardASCII();
	}
	virtual size_t Fold(char *folded, size_t sizeFolded, const char *mixed, size_t lenMixed) {
		if ((lenMixed == 1) && (sizeFolded > 0)) {
			folded[0] = mapping[static_cast<unsigned char>(mixed[0])];
			return 1;
		} else {
            CFStringRef cfsVal = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                         reinterpret_cast<const UInt8 *>(mixed), 
                                                         lenMixed, encoding, false);

            NSString *sMapped = [(NSString *)cfsVal stringByFoldingWithOptions:NSCaseInsensitiveSearch
                                                                        locale:[NSLocale currentLocale]];
            
            char *encoded = EncodedBytes((CFStringRef)sMapped, encoding);

			size_t lenMapped = strlen(encoded);
            if (lenMapped < sizeFolded) {
                memcpy(folded, encoded,  lenMapped);
            } else {
                folded[0] = '\0';
                lenMapped = 1;
            }
            delete []encoded;
            CFRelease(cfsVal);
			return lenMapped;
		}
		// Something failed so return a single NUL byte
		folded[0] = '\0';
		return 1;
	}
};

CaseFolder *ScintillaCocoa::CaseFolderForEncoding() {
	if (pdoc->dbcsCodePage == SC_CP_UTF8) {
		return new CaseFolderUnicode();
	} else {
        CFStringEncoding encoding = EncodingFromCharacterSet(IsUnicodeMode(),
                                                             vs.styles[STYLE_DEFAULT].characterSet);
        if (pdoc->dbcsCodePage == 0) {
            CaseFolderTable *pcf = new CaseFolderTable();
            pcf->StandardASCII();
            // Only for single byte encodings
            for (int i=0x80; i<0x100; i++) {
                char sCharacter[2] = "A";
                sCharacter[0] = i;
                CFStringRef cfsVal = CFStringCreateWithBytes(kCFAllocatorDefault,
                                                             reinterpret_cast<const UInt8 *>(sCharacter), 
                                                             1, encoding, false);
                if (!cfsVal)
                        continue;
                
                NSString *sMapped = [(NSString *)cfsVal stringByFoldingWithOptions:NSCaseInsensitiveSearch
                                                                            locale:[NSLocale currentLocale]];
                
                char *encoded = EncodedBytes((CFStringRef)sMapped, encoding);
                
                if (strlen(encoded) == 1) {
                    pcf->SetTranslation(sCharacter[0], encoded[0]);
                }
                
                delete []encoded;
                CFRelease(cfsVal);
            }
            return pcf;
        } else {
            return new CaseFolderDBCS(encoding);
        }
		return 0;
	}
}


//--------------------------------------------------------------------------------------------------

/**
 * Case-fold the given string depending on the specified case mapping type.
 */
std::string ScintillaCocoa::CaseMapString(const std::string &s, int caseMapping)
{
  if ((s.size() == 0) || (caseMapping == cmSame))
    return s;
  
  if (IsUnicodeMode()) {
    std::string retMapped(s.length() * maxExpansionCaseConversion, 0);
    size_t lenMapped = CaseConvertString(&retMapped[0], retMapped.length(), s.c_str(), s.length(), 
      (caseMapping == cmUpper) ? CaseConversionUpper : CaseConversionLower);
    retMapped.resize(lenMapped);
    return retMapped;
  }

  CFStringEncoding encoding = EncodingFromCharacterSet(IsUnicodeMode(),
                                                       vs.styles[STYLE_DEFAULT].characterSet);
  CFStringRef cfsVal = CFStringCreateWithBytes(kCFAllocatorDefault,
                                               reinterpret_cast<const UInt8 *>(s.c_str()), 
                                               s.length(), encoding, false);

  NSString *sMapped;
  switch (caseMapping)
  {
    case cmUpper:
      sMapped = [(NSString *)cfsVal uppercaseString];
      break;
    case cmLower:
      sMapped = [(NSString *)cfsVal lowercaseString];
      break;
    default:
      sMapped = (NSString *)cfsVal;
  }

  // Back to encoding
  char *encoded = EncodedBytes((CFStringRef)sMapped, encoding);
  std::string result(encoded);
  delete []encoded;
  CFRelease(cfsVal);
  return result;
}

//--------------------------------------------------------------------------------------------------

/**
 * Cancel all modes, both for base class and any find indicator.
 */
void ScintillaCocoa::CancelModes() {
  ScintillaBase::CancelModes();
  HideFindIndicator();
}

//--------------------------------------------------------------------------------------------------

/**
 * Helper function to get the outer container which represents the Scintilla editor on application side.
 */
ScintillaView* ScintillaCocoa::TopContainer()
{
  UIView* container = static_cast<UIView*>(wMain.GetID());
  return static_cast<ScintillaView*>([[[container superview] superview] superview]);
}

//--------------------------------------------------------------------------------------------------

/**
 * Helper function to get the scrolling view.
 */
UIScrollView* ScintillaCocoa::ScrollContainer() {
  UIView* container = static_cast<UIView*>(wMain.GetID());
  return static_cast<UIScrollView*>([container superview]);
}

//--------------------------------------------------------------------------------------------------

/**
 * Helper function to get the inner container which represents the actual "canvas" we work with.
 */
SCIContentView* ScintillaCocoa::ContentView()
{
  return static_cast<SCIContentView*>(wMain.GetID());
}

//--------------------------------------------------------------------------------------------------

/**
 * Return the top left visible point relative to the origin point of the whole document.
 */
Scintilla::Point ScintillaCocoa::GetVisibleOriginInMain()
{
    SCIContentView* contentView = ContentView();
    CGRect contentRect = contentView.frame;
    return Point(contentRect.origin.x, contentRect.origin.y);
}

//--------------------------------------------------------------------------------------------------

/**
 * Instead of returning the size of the inner view we have to return the visible part of it
 * in order to make scrolling working properly.
 * The returned value is in document coordinates.
 */
PRectangle ScintillaCocoa::GetClientRectangle()
{
    SCIContentView* contentView = ContentView();
    CGSize size = [contentView bounds].size;
    return PRectangle(0, 0, size.width, size.height);
}

//--------------------------------------------------------------------------------------------------

/**
 * Converts the given point from base coordinates to local coordinates and at the same time into
 * a native Point structure. Base coordinates are used for the top window used in the view hierarchy.
 * Returned value is in view coordinates. 
 */
Scintilla::Point ScintillaCocoa::ConvertPoint(CGPoint point)
{
  return Point(point.x, point.y);
}

//--------------------------------------------------------------------------------------------------

/**
 * A function to directly execute code that would usually go the long way via window messages.
 * However this is a Windows metaphor and not used here, hence we just call our fake
 * window proc. The given parameters directly reflect the message parameters used on Windows.
 *
 * @param sciThis The target which is to be called.
 * @param iMessage A code that indicates which message was sent.
 * @param wParam One of the two free parameters for the message. Traditionally a word sized parameter 
 *               (hence the w prefix).
 * @param lParam The other of the two free parameters. A signed long.
 */
sptr_t ScintillaCocoa::DirectFunction(ScintillaCocoa *sciThis, unsigned int iMessage, uptr_t wParam, 
                                      sptr_t lParam)
{
  return sciThis->WndProc(iMessage, wParam, lParam);
}

//--------------------------------------------------------------------------------------------------

/**
 * This method is very similar to DirectFunction. On Windows it sends a message (not in the Obj-C sense)
 * to the target window. Here we simply call our fake window proc.
 */
sptr_t scintilla_send_message(void* sci, unsigned int iMessage, uptr_t wParam, sptr_t lParam)
{
  ScintillaView *control = reinterpret_cast<ScintillaView*>(sci);
  ScintillaCocoa* scintilla = [control backend];
  return scintilla->WndProc(iMessage, wParam, lParam);
}

//--------------------------------------------------------------------------------------------------

/**
 * That's our fake window procedure. On Windows each window has a dedicated procedure to handle
 * commands (also used to synchronize UI and background threads), which is not the case in Cocoa.
 *
 * Messages handled here are almost solely for special commands of the backend. Everything which
 * would be system messages on Windows (e.g. for key down, mouse move etc.) are handled by
 * directly calling appropriate handlers.
 */
sptr_t ScintillaCocoa::WndProc(unsigned int iMessage, uptr_t wParam, sptr_t lParam)
{
  switch (iMessage)
  {
    case SCI_GETDIRECTFUNCTION:
      return reinterpret_cast<sptr_t>(DirectFunction);
      
    case SCI_GETDIRECTPOINTER:
      return reinterpret_cast<sptr_t>(this);
      
    case SCI_GRABFOCUS:
      [ContentView() becomeFirstResponder];
      break;
      
    case SCI_SETBUFFEREDDRAW:
      // Buffered drawing not supported on Cocoa
      bufferedDraw = false;
      break;
      
    case SCI_FINDINDICATORSHOW:
      ShowFindIndicatorForRange(NSMakeRange(wParam, lParam-wParam), YES);
      return 0;
      
    case SCI_FINDINDICATORFLASH:
      ShowFindIndicatorForRange(NSMakeRange(wParam, lParam-wParam), NO);
      return 0;
      
    case SCI_FINDINDICATORHIDE:
      HideFindIndicator();
      return 0;
      
    default:
      sptr_t r = ScintillaBase::WndProc(iMessage, wParam, lParam);
      
      return r;
  }
  return 0l;
}

//--------------------------------------------------------------------------------------------------

/**
 * In Windows lingo this is the handler which handles anything that wasn't handled in the normal 
 * window proc which would usually send the message back to generic window proc that Windows uses.
 */
sptr_t ScintillaCocoa::DefWndProc(unsigned int, uptr_t, sptr_t)
{
  return 0;
}

//--------------------------------------------------------------------------------------------------

/**
 * Enables or disables a timer that can trigger background processing at a regular interval, like
 * drag scrolling or caret blinking.
 */
void ScintillaCocoa::SetTicking(bool on)
{
  if (timer.ticking != on)
  {
    timer.ticking = on;
    if (timer.ticking)
    {
      // Scintilla ticks = milliseconds
      tickTimer = [NSTimer scheduledTimerWithTimeInterval: timer.tickSize / 1000.0
						   target: timerTarget
						 selector: @selector(timerFired:)
						 userInfo: nil
						  repeats: YES];
      timer.tickerID = reinterpret_cast<TickerID>(tickTimer);
    }
    else
      if (timer.tickerID != NULL)
      {
        [reinterpret_cast<NSTimer*>(timer.tickerID) invalidate];
        timer.tickerID = 0;
      }
  }
  timer.ticksToWait = caret.period;
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::SetIdle(bool on)
{
  if (idler.state != on)
  {
    idler.state = on;
    if (idler.state)
    {
      // Scintilla ticks = milliseconds
      idleTimer = [NSTimer scheduledTimerWithTimeInterval: timer.tickSize / 1000.0
						   target: timerTarget
						 selector: @selector(idleTimerFired:)
						 userInfo: nil
						  repeats: YES];
      idler.idlerID = reinterpret_cast<IdlerID>(idleTimer);
    }
    else
      if (idler.idlerID != NULL)
      {
        [reinterpret_cast<NSTimer*>(idler.idlerID) invalidate];
        idler.idlerID = 0;
      }
  }
  return true;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::CopyToClipboard(const SelectionText &selectedText)
{
  SetPasteboardData([UIPasteboard generalPasteboard], selectedText);
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::Copy()
{
  if (!sel.Empty())
  {
    SelectionText selectedText;
    CopySelectionRange(&selectedText);
    CopyToClipboard(selectedText);
  }
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::CanPaste()
{
  if (!Editor::CanPaste())
    return false;
  
  return GetPasteboardData([UIPasteboard generalPasteboard], NULL);
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::Paste()
{
  Paste(false);
}

//--------------------------------------------------------------------------------------------------

/**
 * Pastes data from the paste board into the editor.
 */
void ScintillaCocoa::Paste(bool forceRectangular)
{
  SelectionText selectedText;
  bool ok = GetPasteboardData([UIPasteboard generalPasteboard], &selectedText);
  if (forceRectangular)
    selectedText.rectangular = forceRectangular;
  
  if (!ok || selectedText.Empty())
    // No data or no flavor we support.
    return;
  
  pdoc->BeginUndoAction();
  ClearSelection(false);
  int length = (int)selectedText.Length();
  if (selectedText.rectangular)
  {
    SelectionPosition selStart = sel.RangeMain().Start();
    PasteRectangular(selStart, selectedText.Data(), length);
  }
  else 
    if (pdoc->InsertString(sel.RangeMain().caret.Position(), selectedText.Data(), length))
      SetEmptySelection(sel.RangeMain().caret.Position() + length);
  
  pdoc->EndUndoAction();
  
  Redraw();
  EnsureCaretVisible();
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::CTPaint(void* gc, CGRect rc) {
#pragma unused(rc)
    Surface *surfaceWindow = Surface::Allocate(SC_TECHNOLOGY_DEFAULT);
    if (surfaceWindow) {
        surfaceWindow->Init(gc, wMain.GetID());
        surfaceWindow->SetUnicodeMode(SC_CP_UTF8 == ct.codePage);
        surfaceWindow->SetDBCSMode(ct.codePage);
        ct.PaintCT(surfaceWindow);
        surfaceWindow->Release();
        delete surfaceWindow;
    }
}

@interface CallTipView : UIControl {
    ScintillaCocoa *sci;
}

@end

@implementation CallTipView

- (UIView*) initWithFrame: (CGRect) frame {
	self = [super initWithFrame: frame];

	if (self) {
        sci = NULL;
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (BOOL) isFlipped {
	return YES;
}

- (void) setSci: (ScintillaCocoa *) sci_ {
    sci = sci_;
}

- (void) drawRect: (CGRect) needsDisplayInRect {
    if (sci) {
        CGContextRef context = (CGContextRef) UIGraphicsGetCurrentContext();
        sci->CTPaint(context, needsDisplayInRect);
    }
}

// On OS X, only the key view should modify the cursor so the calltip can't.
// This view does not become key so resetCursorRects never called.
- (void) resetCursorRects {
    //[super resetCursorRects];
    //[self addCursorRect: [self bounds] cursor: [NSCursor arrowCursor]];
}

@end

void ScintillaCocoa::CallTipMouseDown(CGPoint pt) {
    CGRect rectBounds = [(UIView *)(ct.wDraw.GetID()) bounds];
    Point location(pt.x, rectBounds.size.height - pt.y);
    ct.MouseClick(location);
    CallTipClick();
}

void ScintillaCocoa::CreateCallTipWindow(PRectangle rc) {
//    if (!ct.wCallTip.Created()) {
//        CGRect ctRect = NSMakeRect(rc.top,rc.bottom, rc.Width(), rc.Height());
//        NSWindow *callTip = [[NSWindow alloc] initWithContentRect: ctRect 
//                                                        styleMask: NSBorderlessWindowMask
//                                                          backing: NSBackingStoreBuffered
//                                                            defer: NO];
//        [callTip setLevel:NSFloatingWindowLevel];
//        [callTip setHasShadow:YES];
//        NSRect ctContent = NSMakeRect(0,0, rc.Width(), rc.Height());
//        CallTipView *caption = [[CallTipView alloc] initWithFrame: ctContent];
//        [caption setAutoresizingMask: NSViewWidthSizable | NSViewMaxYMargin];
//        [caption setSci: this];
//        [[callTip contentView] addSubview: caption];
//        [callTip orderFront:caption];
//        ct.wCallTip = callTip;
//        ct.wDraw = caption;
//    }
}

void ScintillaCocoa::AddToPopUp(const char *label, int cmd, bool enabled)
{
}

// -------------------------------------------------------------------------------------------------

void ScintillaCocoa::ClaimSelection()
{
  // Mac OS X does not have a primary selection.
}

// -------------------------------------------------------------------------------------------------

/**
 * Returns the current caret position (which is tracked as an offset into the entire text string)
 * as a row:column pair. The result is zero-based.
 */
CGPoint ScintillaCocoa::GetCaretPosition()
{
  CGPoint result;

  result.y = pdoc->LineFromPosition(sel.RangeMain().caret.Position());
  result.x = sel.RangeMain().caret.Position() - pdoc->LineStart(result.y);
  return result;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::SetPasteboardData(UIPasteboard* board, const SelectionText &selectedText)
{
  if (selectedText.Length() == 0)
    return;

  CFStringEncoding encoding = EncodingFromCharacterSet(selectedText.codePage == SC_CP_UTF8,
                                                       selectedText.characterSet);
  CFStringRef cfsVal = CFStringCreateWithBytes(kCFAllocatorDefault,
                                               reinterpret_cast<const UInt8 *>(selectedText.Data()),
                                               selectedText.Length(), encoding, false);

  [board setString: (NSString *)cfsVal];

  if (cfsVal)
    CFRelease(cfsVal);
}

//--------------------------------------------------------------------------------------------------

/**
 * Helper method to retrieve the best fitting alternative from the general pasteboard.
 */
bool ScintillaCocoa::GetPasteboardData(UIPasteboard* board, SelectionText* selectedText)
{
  NSString* data = [board string];
  
  if (data != nil)
  {
    if (selectedText != nil)
    {
      CFStringEncoding encoding = EncodingFromCharacterSet(IsUnicodeMode(),
                                                           vs.styles[STYLE_DEFAULT].characterSet);
      CFRange rangeAll = {0, static_cast<CFIndex>([data length])};
      CFIndex usedLen = 0;
      CFStringGetBytes((CFStringRef)data, rangeAll, encoding, '?',
                       false, NULL, 0, &usedLen);

      std::vector<UInt8> buffer(usedLen);
    
      CFStringGetBytes((CFStringRef)data, rangeAll, encoding, '?',
                       false, buffer.data(),usedLen, NULL);

      int len = static_cast<int>(usedLen);
      std::string dest = Document::TransformLineEnds((char *)buffer.data(), len, pdoc->eolMode);

      selectedText->Copy(dest, pdoc->dbcsCodePage,
                         vs.styles[STYLE_DEFAULT].characterSet , NO, false);
    }
    return true;
  }
  
  return false;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::SetMouseCapture(bool on)
{
  capturedMouse = on;
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::HaveMouseCapture()
{
  return capturedMouse;
}

//--------------------------------------------------------------------------------------------------

/**
 * Synchronously paint a rectangle of the window.
 */
bool ScintillaCocoa::SyncPaint(void* gc, PRectangle rc)
{
  /* transform coords */
//    Point ptOrigin = GetVisibleOriginInMain();
//    rc.Move(ptOrigin.x, ptOrigin.y);
  //CGContextTranslateCTM((CGContextRef)gc, ptOrigin.x, ptOrigin.y);
    
  paintState = painting;
  rcPaint = rc;
  PRectangle rcText = GetTextRectangle();
  paintingAllText = rcPaint.Contains(rcText);
  bool succeeded = true;
  Surface *sw = Surface::Allocate(SC_TECHNOLOGY_DEFAULT);
  if (sw)
  {
    CGContextSetAllowsAntialiasing((CGContextRef)gc,
                                   vs.extraFontFlag != SC_EFF_QUALITY_NON_ANTIALIASED);
    CGContextSetAllowsFontSmoothing((CGContextRef)gc,
                                    vs.extraFontFlag == SC_EFF_QUALITY_LCD_OPTIMIZED);
    if (CGContextSetAllowsFontSubpixelPositioning != NULL)
      CGContextSetAllowsFontSubpixelPositioning((CGContextRef)gc,
						vs.extraFontFlag == SC_EFF_QUALITY_DEFAULT ||
						vs.extraFontFlag == SC_EFF_QUALITY_LCD_OPTIMIZED);
    sw->Init(gc, wMain.GetID());
    Paint(sw, rc);
    succeeded = paintState != paintAbandoned;
    sw->Release();
    delete sw;
  }
  paintState = notPainting;
//  if (!succeeded)
//  {
//    UIView *marginView = static_cast<UIView*>(wMargin.GetID());
//    [marginView setNeedsDisplay];
//  }
  return succeeded;
}

//--------------------------------------------------------------------------------------------------

/**
 * Paint the margin into the SCIMarginView space.
 */
void ScintillaCocoa::PaintMargin(CGRect aRect)
{
  CGContextRef gc = (CGContextRef) UIGraphicsGetCurrentContext();

  PRectangle rc = CGRectToPRectangle(aRect);
  rcPaint = rc;
  Surface *sw = Surface::Allocate(SC_TECHNOLOGY_DEFAULT);
  if (sw)
  {
    sw->Init(gc, wMargin.GetID());
    PaintSelMargin(sw, rc);
    sw->Release();
    delete sw;
  }
}

//--------------------------------------------------------------------------------------------------

/**
 * ScrollText is empty because scrolling is handled by the NSScrollView.
 */
void ScintillaCocoa::ScrollText(int linesToMove)
{
}

//--------------------------------------------------------------------------------------------------

/**
 * Modifies the vertical scroll position to make the current top line show up as such.
 */
void ScintillaCocoa::SetVerticalScrollPos()
{
  UIScrollView *scrollView = ScrollContainer();
  if (scrollView) {
    CGPoint orign = CGPointMake(scrollView.contentOffset.x, topLine * vs.lineHeight);
    [scrollView setContentOffset:orign];
  }
}

//--------------------------------------------------------------------------------------------------

/**
 * Modifies the horizontal scroll position to match xOffset.
 */
void ScintillaCocoa::SetHorizontalScrollPos()
{
  PRectangle textRect = GetTextRectangle();

  int maxXOffset = scrollWidth - textRect.Width();
  if (maxXOffset < 0)
    maxXOffset = 0;
  if (xOffset > maxXOffset)
    xOffset = maxXOffset;
  UIScrollView *scrollView = ScrollContainer();
  if (scrollView) {
    CGPoint orign = CGPointMake(xOffset, scrollView.contentOffset.y);
    [scrollView setContentOffset:orign];
  }
  MoveFindIndicatorWithBounce(NO);
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to adjust both scrollers to reflect the current scroll range and position in the editor.
 * Arguments no longer used as NSScrollView handles details of scroll bar sizes.
 *
 * @param nMax Number of lines in the editor.
 * @param nPage Number of lines per scroll page.
 * @return True if there was a change, otherwise false.
 */
bool ScintillaCocoa::ModifyScrollBars(int nMax, int nPage)
{
#pragma unused(nMax, nPage)
  return SetScrollingSize();
}

bool ScintillaCocoa::SetScrollingSize(void) {
	bool changes = false;
	SCIContentView *inner = ContentView();
	if (!enteredSetScrollingSize) {
		enteredSetScrollingSize = true;
		UIScrollView *scrollView = ScrollContainer();
		CGRect clipRect = [scrollView bounds];
        clipRect.size.width -= scrollView.contentInset.right + scrollView.contentInset.left;
        clipRect.size.height -= scrollView.contentInset.top + scrollView.contentInset.bottom;
		CGFloat docHeight = (cs.LinesDisplayed()+1) * vs.lineHeight;
		if (!endAtLastLine)
			docHeight += (int([scrollView bounds].size.height / vs.lineHeight)-3) * vs.lineHeight;
		// Allow extra space so that last scroll position places whole line at top
		int clipExtra = int(clipRect.size.height) % vs.lineHeight;
		docHeight += clipExtra;
		// Ensure all of clipRect covered by Scintilla drawing
		if (docHeight < clipRect.size.height)
			docHeight = clipRect.size.height;
		CGFloat docWidth = scrollWidth;
		bool showHorizontalScroll = horizontalScrollBarVisible &&
			!Wrapping();
		if (!showHorizontalScroll)
			docWidth = clipRect.size.width;
		CGSize contentSize = {docWidth, docHeight};
        [inner setFrame: clipRect];
        scrollView.contentSize = contentSize;
		SetVerticalScrollPos();
		enteredSetScrollingSize = false;
	}
	return changes;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::Resize()
{
  SetScrollingSize();
  ChangeSize();
}

//--------------------------------------------------------------------------------------------------

/**
 * Update fields to match scroll position after receiving a notification that the user has scrolled.
 */
void ScintillaCocoa::UpdateForScroll() {
  Point ptOrigin = GetVisibleOriginInMain();
  xOffset = ptOrigin.x;
  int newTop = Platform::Minimum(ptOrigin.y / vs.lineHeight, MaxScrollPos());
  SetTopLine(newTop);
}

//--------------------------------------------------------------------------------------------------

/**
 * Register a delegate that will be called for notifications and commands.
 * This provides similar functionality to RegisterNotifyCallback but in an
 * Objective C way.
 *
 * @param delegate_ A pointer to an object that implements ScintillaNotificationProtocol.
 */

void ScintillaCocoa::SetDelegate(id<ScintillaNotificationProtocol> delegate_)
{
  delegate = delegate_;
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to register a callback function for a given window. This is used to emulate the way
 * Windows notifies other controls (mainly up in the view hierarchy) about certain events.
 *
 * @param windowid A handle to a window. That value is generic and can be anything. It is passed
 *                 through to the callback.
 * @param callback The callback function to be used for future notifications. If NULL then no
 *                 notifications will be sent anymore.
 */
void ScintillaCocoa::RegisterNotifyCallback(intptr_t windowid, SciNotifyFunc callback)
{
  notifyObj = windowid;
  notifyProc = callback;
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::NotifyChange()
{
  if (notifyProc != NULL)
    notifyProc(notifyObj, WM_COMMAND, Platform::LongFromTwoShorts(GetCtrlID(), SCEN_CHANGE),
	       (uintptr_t) this);
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::NotifyFocus(bool focus)
{
  if (notifyProc != NULL)
    notifyProc(notifyObj, WM_COMMAND, Platform::LongFromTwoShorts(GetCtrlID(), (focus ? SCEN_SETFOCUS : SCEN_KILLFOCUS)),
	       (uintptr_t) this);

  Editor::NotifyFocus(focus);
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to send a notification (as WM_NOTIFY call) to the procedure, which has been set by the call
 * to RegisterNotifyCallback (so it is not necessarily the parent window).
 *
 * @param scn The notification to send.
 */
void ScintillaCocoa::NotifyParent(SCNotification scn)
{ 
  scn.nmhdr.hwndFrom = (void*) this;
  scn.nmhdr.idFrom = GetCtrlID();
  if (notifyProc != NULL)
    notifyProc(notifyObj, WM_NOTIFY, GetCtrlID(), (uintptr_t) &scn);
  if (delegate)
    [delegate notification:&scn];
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::NotifyURIDropped(const char *uri)
{
  SCNotification scn;
  scn.nmhdr.code = SCN_URIDROPPED;
  scn.text = uri;
  
  NotifyParent(scn);
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::HasSelection()
{
  return !sel.Empty();
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::CanUndo()
{
  return pdoc->CanUndo();
}

//--------------------------------------------------------------------------------------------------

bool ScintillaCocoa::CanRedo()
{
  return pdoc->CanRedo();
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::TimerFired(NSTimer* timer)
{
#pragma unused(timer)
  Tick();
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::IdleTimerFired()
{
  bool more = Idle();
  if (!more)
    SetIdle(false);
}

//--------------------------------------------------------------------------------------------------

/**
 * Main entry point for drawing the control.
 *
 * @param rect The area to paint, given in the sender's coordinate system.
 * @param gc The context we can use to paint.
 */
bool ScintillaCocoa::Draw(CGRect rect, CGContextRef gc)
{
  return SyncPaint(gc, CGRectToPRectangle(rect));
}

//--------------------------------------------------------------------------------------------------
    
/**
 * Helper function to translate OS X key codes to Scintilla key codes.
 */
static inline UniChar KeyTranslate(UniChar unicodeChar)
{
  switch (unicodeChar)
  {
//    case NSDownArrowFunctionKey:
//      return SCK_DOWN;
//    case NSUpArrowFunctionKey:
//      return SCK_UP;
//    case NSLeftArrowFunctionKey:
//      return SCK_LEFT;
//    case NSRightArrowFunctionKey:
//      return SCK_RIGHT;
//    case NSHomeFunctionKey:
//      return SCK_HOME;
//    case NSEndFunctionKey:
//      return SCK_END;
//    case NSPageUpFunctionKey:
//      return SCK_PRIOR;
//    case NSPageDownFunctionKey:
//      return SCK_NEXT;
//    case NSDeleteFunctionKey:
//      return SCK_DELETE;
//    case NSInsertFunctionKey:
//      return SCK_INSERT;
    case '\n':
    case 3:
      return SCK_RETURN;
    case 27:
      return SCK_ESCAPE;
    case 127:
      return SCK_BACK;
    case '\t':
    case 25: // Shift tab, return to unmodified tab and handle that via modifiers.
      return SCK_TAB;
    default:
      return unicodeChar;
  }
}


//--------------------------------------------------------------------------------------------------

/**
 * Main keyboard input handling method. It is called for any key down event, including function keys,
 * numeric keypad input and whatnot. 
 *
 * @param event The event instance associated with the key down event.
 * @return True if the input was handled, false otherwise.
 */
bool ScintillaCocoa::KeyboardInput(NSString* input)
{
  // For now filter out function keys.

  
  bool handled = false;
  
  // Handle each entry individually. Usually we only have one entry anyway.
  for (size_t i = 0; i < input.length; i++)
  {
    const UniChar originalKey = [input characterAtIndex: i];
    UniChar key = KeyTranslate(originalKey);
    
    bool consumed = false; // Consumed as command?
    
    if (KeyDownWithModifiers(key, 0, &consumed))
      handled = true;
    if (consumed)
      handled = true;
  }
  
  return handled;
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to insert already processed text provided by the Cocoa text input system.
 */
int ScintillaCocoa::InsertText(NSString* input)
{
  CFStringEncoding encoding = EncodingFromCharacterSet(IsUnicodeMode(),
                                                         vs.styles[STYLE_DEFAULT].characterSet);
  CFRange rangeAll = {0, static_cast<CFIndex>([input length])};
  CFIndex usedLen = 0;
  CFStringGetBytes((CFStringRef)input, rangeAll, encoding, '?',
                   false, NULL, 0, &usedLen);
    
  std::vector<UInt8> buffer(usedLen);
    
  CFStringGetBytes((CFStringRef)input, rangeAll, encoding, '?',
                     false, buffer.data(),usedLen, NULL);
    
  AddCharUTF((char*) buffer.data(), static_cast<unsigned int>(usedLen), false);
  return static_cast<int>(usedLen);
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to ensure that only one selection is active for input composition as composition
 * does not support multi-typing.
 * Also drop virtual space as that is not supported by composition.
 */
void ScintillaCocoa::SelectOnlyMainSelection()
{
  SelectionRange mainSel = sel.RangeMain();
  mainSel.ClearVirtualSpace();
  sel.SetSelection(mainSel);
  Redraw();
}

//--------------------------------------------------------------------------------------------------
/**
 * When switching documents discard any incomplete character composition state as otherwise tries to
 * act on the new document.
 */
void ScintillaCocoa::SetDocPointer(Document *document)
{
  // Drop input composition.
  Editor::SetDocPointer(document);
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::SingleTap(CGPoint location)
{
    Point p = ConvertPoint(location);
    ButtonDown(p, 1000, NO, NO, NO);
    ButtonUp(p, 1000, NO);
}

// Helper methods for NSResponder actions.

void ScintillaCocoa::SelectAll()
{
  Editor::SelectAll();
}

void ScintillaCocoa::DeleteBackward()
{
  KeyDown(SCK_BACK, false, false, false, nil);
}

void ScintillaCocoa::Cut()
{
  Editor::Cut();
}

void ScintillaCocoa::Undo()
{
  Editor::Undo();
}

void ScintillaCocoa::Redo()
{
  Editor::Redo();
}


//--------------------------------------------------------------------------------------------------

/**
 * An intermediate function to forward context menu commands from the menu action handler to
 * scintilla.
 */
void ScintillaCocoa::HandleCommand(NSInteger command)
{
  Command(static_cast<int>(command));
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::ActiveStateChanged(bool isActive)
{
  // If the window is being deactivated, lose the focus and turn off the ticking
  if (!isActive) {
    DropCaret();
    //SetFocusState( false );
    SetTicking( false );
  } else {
    ShowCaretAtCurrentPosition();
  }
}

/* semyonc */
CGRect ScintillaCocoa::GetScreenSelectLineRect()
{
    Point pt = LocationFromPosition(sel.RangeMain().caret.Position());
    UIView *content = ContentView();
    return CGRectMake(vs.textStart - xOffset, pt.y,
                      [content frame].size.width, pt.y + vs.lineHeight);
}

bool ScintillaCocoa::PointInSelMargin(CGPoint p)
{
    return Editor::PointInSelMargin(ConvertPoint(p));
}

//--------------------------------------------------------------------------------------------------

void ScintillaCocoa::ShowFindIndicatorForRange(NSRange charRange, BOOL retaining)
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
  UIView *content = ContentView();
  if (!layerFindIndicator)
  {
    layerFindIndicator = [[FindHighlightLayer alloc] init];
    layerFindIndicator.geometryFlipped = !content.layer.geometryFlipped; /* semyonc iOS */
    [[content layer] addSublayer:layerFindIndicator];
  }
  [layerFindIndicator removeAnimationForKey:@"animateFound"];
  
  if (charRange.length)
  {
    CFStringEncoding encoding = EncodingFromCharacterSet(IsUnicodeMode(),
							 vs.styles[STYLE_DEFAULT].characterSet);
    std::vector<char> buffer(charRange.length);
    pdoc->GetCharRange(&buffer[0], (int)charRange.location, (int)charRange.length);
    
    CFStringRef cfsFind = CFStringCreateWithBytes(kCFAllocatorDefault,
						  reinterpret_cast<const UInt8 *>(&buffer[0]), 
						  charRange.length, encoding, false);
    layerFindIndicator.sFind = (NSString *)cfsFind;
    if (cfsFind)
        CFRelease(cfsFind);
    layerFindIndicator.retaining = retaining;
    layerFindIndicator.positionFind = (int)charRange.location;
    sptr_t style = WndProc(SCI_GETSTYLEAT, charRange.location, 0);
    sptr_t len = WndProc(SCI_STYLEGETFONT, style, 0);
    if (len == 0) {
        style = STYLE_DEFAULT;
        len = WndProc(SCI_STYLEGETFONT, style, 0);
    }
    std::vector<char> bufferFontName(len + 1);
    WndProc(SCI_STYLEGETFONT, style, (sptr_t)&bufferFontName[0]);
    layerFindIndicator.sFont = [NSString stringWithUTF8String: &bufferFontName[0]];
    layerFindIndicator.fontSize = WndProc(SCI_STYLEGETSIZEFRACTIONAL, style, 0) / 
      (float)SC_FONT_SIZE_MULTIPLIER;
    /* semyonc */
    UIFont *font = [UIFont fontWithName:layerFindIndicator.sFont size:layerFindIndicator.fontSize];
    layerFindIndicator.widthText = [layerFindIndicator.sFind
        sizeWithAttributes:@{NSFontAttributeName:font}].width;
    layerFindIndicator.heightLine = WndProc(SCI_TEXTHEIGHT, 0, 0);
    MoveFindIndicatorWithBounce(YES);
  }
  else
  {
    [layerFindIndicator hideMatch];
  }
#endif
}

void ScintillaCocoa::MoveFindIndicatorWithBounce(BOOL bounce)
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
  if (layerFindIndicator)
  {
    CGPoint ptText = CGPointMake(
      WndProc(SCI_POINTXFROMPOSITION, 0, layerFindIndicator.positionFind),
      WndProc(SCI_POINTYFROMPOSITION, 0, layerFindIndicator.positionFind));
    ptText.x = ptText.x /* - vs.fixedColumnWidth */ + xOffset;
    //ptText.y += topLine * vs.lineHeight; /* semyonc */
    if (!layerFindIndicator.geometryFlipped)
    {
      UIView *content = ContentView();
      ptText.y = content.bounds.size.height - ptText.y;
    }
    [layerFindIndicator animateMatch:ptText bounce:bounce];
  }
#endif
}

void ScintillaCocoa::HideFindIndicator()
{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
  if (layerFindIndicator)
  {
    [layerFindIndicator hideMatch];
  }
#endif
}


