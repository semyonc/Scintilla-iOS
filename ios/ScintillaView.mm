
/**
 * Implementation of the native Cocoa View that serves as container for the scintilla parts.
 *
 * Created by Mike Lischke.
 *
 * Copyright 2011, 2013, Oracle and/or its affiliates. All rights reserved.
 * Copyright 2009, 2011 Sun Microsystems, Inc. All rights reserved.
 * This file is dual licensed under LGPL v2.1 and the Scintilla license (http://www.scintilla.org/License.txt).
 */

#import "Platform.h"
#import "ScintillaView.h"
#import "ScintillaCocoa.h"

using namespace Scintilla;


// The scintilla indicator used for keyboard input.
#define INPUT_INDICATOR INDIC_MAX - 1

NSString *const SCIUpdateUINotification = @"SCIUpdateUI";


@implementation SCIContentView

@synthesize owner = mOwner;
@synthesize markedRangeBorderColor = _markedRangeBorderColor;
@synthesize markedRangeBackgroundColor = _markedRangeBackgroundColor;
@synthesize markedRangeBorderThickness = _markedRangeBorderThickness;
@synthesize keyboardAppearance = _keyboardAppearance;


static void do_init(SCIContentView* self)
{
    self->_autocorrectionType = UITextAutocorrectionTypeDefault;
    self->_autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self->_keyboardType = UIKeyboardTypeDefault;
    self.markedRangeBorderColor = [UIColor colorWithRed:213.0/255.0 green:225.0/255.0 blue:237.0/255.0 alpha:1];
    self->_markedRangeBorderThickness = 1.0;
    self.markedRangeBackgroundColor = [UIColor colorWithRed:236.0/255.0 green:240.0/255.0 blue:248.0/255.0 alpha:1];
    //self->_keyboardAppearance = UIKeyboardAppearanceLight;
}

- (UIView*) initWithFrame: (CGRect) frame
{
  self = [super initWithFrame: frame];
  
  if (self != nil)
  {
      do_init(self);
      
      selectMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Select", nil)
                                                  action:@selector(selectText:)];
      
      UIGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc]
                             initWithTarget:self action:@selector(handleTapGesture:)];
      [self addGestureRecognizer:singleTapRecognizer];
      [singleTapRecognizer release];
      
      UIGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
      [self addGestureRecognizer:longPressRecognizer];
      [longPressRecognizer release];
      
      [[NSNotificationCenter defaultCenter] addObserver: self
            selector: @selector(orientationDidChange:)
            name: UIApplicationDidChangeStatusBarOrientationNotification
            object: nil];
  }
  
  return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
    [_loupe release];
    [startThumb release];
    [endThumb release];
    [selectMenuItem release];
    [super dealloc];
}

-(NSArray*)keyCommands
{
    return @[
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                 modifierFlags:0 action:@selector(presssLineUp:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                 modifierFlags:UIKeyModifierShift action:@selector(presssLineUpExtend:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                 modifierFlags:0 action:@selector(pressLineDown:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                 modifierFlags:UIKeyModifierShift action:@selector(pressLineDownExtent:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                 modifierFlags:0 action:@selector(pressCharLeft:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                 modifierFlags:UIKeyModifierShift action:@selector(pressCharLeftExtend:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                 modifierFlags:0 action:@selector(pressCharRight:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                 modifierFlags:UIKeyModifierShift action:@selector(pressCharRightExtent:)],
             [UIKeyCommand keyCommandWithInput:@"x"
                                 modifierFlags:UIKeyModifierCommand action:@selector(pressCut:)],
             [UIKeyCommand keyCommandWithInput:@"c"
                                 modifierFlags:UIKeyModifierCommand action:@selector(pressCopy:)],
             [UIKeyCommand keyCommandWithInput:@"p"
                                 modifierFlags:UIKeyModifierCommand action:@selector(pressPaste:)],
             [UIKeyCommand keyCommandWithInput:@"z"
                                 modifierFlags:UIKeyModifierCommand action:@selector(pressUndo:)],
             [UIKeyCommand keyCommandWithInput:@"z"
                                 modifierFlags:UIKeyModifierCommand | UIKeyModifierShift
                                        action:@selector(pressRedo:)]];
}

-(IBAction)presssLineUp:(id)sender
{
    [mOwner message:SCI_LINEUP];
}

-(IBAction)presssLineUpExtend:(id)sender
{
    [mOwner message:SCI_LINEUPEXTEND];
}

-(IBAction)pressLineDown:(id)sender
{
    [mOwner message:SCI_LINEDOWN];
}

-(IBAction)pressLineDownExtent:(id)sender
{
    [mOwner message:SCI_LINEDOWNEXTEND];
}

-(IBAction)pressCharLeft:(id)sender
{
    [mOwner message:SCI_CHARLEFT];
}

-(IBAction)pressCharLeftExtend:(id)sender
{
    [mOwner message:SCI_CHARLEFTEXTEND];
}

-(IBAction)pressCharRight:(id)sender
{
    [mOwner message:SCI_CHARRIGHT];
}

-(IBAction)pressCharRightExtent:(id)sender
{
    [mOwner message:SCI_CHARRIGHTEXTEND];
}

-(IBAction)pressCut:(id)sender
{
    [mOwner message:SCI_CUT];
}

-(IBAction)pressCopy:(id)sender
{
    [mOwner message:SCI_COPY];
}

-(IBAction)pressPaste:(id)sender
{
    [mOwner message:SCI_PASTE];
}

-(IBAction)pressUndo:(id)sender
{
    [mOwner message:SCI_UNDO];
}

-(IBAction)pressRedo:(id)sender
{
    [mOwner message:SCI_REDO];
}

#pragma mark -
#pragma mark UITextInputTraits protocol

@synthesize autocapitalizationType = _autocapitalizationType;
@synthesize autocorrectionType = _autocorrectionType;
@synthesize keyboardType = _keyboardType;
@synthesize delegate = _delegate;

- (UIKeyboardAppearance)keyboardAppearance;
{
    return UIKeyboardAppearanceDefault;
}

- (UIReturnKeyType)returnKeyType;
{
    return UIReturnKeyDefault;
}

- (BOOL)enablesReturnKeyAutomatically;
{
    return NO;
}

@synthesize autoCorrectDoubleSpaceToPeriodAtSentenceEnd = _autoCorrectDoubleSpaceToPeriodAtSentenceEnd;

- (BOOL)isSecureTextEntry
{
    return NO;
}

- (void)setFrame:(CGRect)newFrame
{
    if (startThumb != nil || endThumb != nil) {
        [self setNeedsLayout]; // Make sure we reposition our overlay views (even if our frame didn't change relative to our superview, it may have changed relative to their superview)
    }
    
    [super setFrame:newFrame];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // We want our thumbs to receive touches even when they extend a bit outside our area.
    
    UIView *hitStartThumb = startThumb? [startThumb hitTest:[self convertPoint:point toView:startThumb] withEvent:event] : nil;
    UIView *hitEndThumb = endThumb? [endThumb hitTest:[self convertPoint:point toView:endThumb] withEvent:event] : nil;
    
    if (hitStartThumb && hitEndThumb) {
        // Direct touches to one thumb or the other depending on closeness, ignoring their z-order.
        // (This comes into play when the thumbs are close enough to each other that their areas overlap.)
        CGFloat dStart = [startThumb distanceFromPoint:point];
        CGFloat dEnd = [endThumb distanceFromPoint:point];
        
        //NSLog(@"start dist: %f, end dist: %f", dStart, dEnd);
        
        if (dStart < dEnd)
            return hitStartThumb;
        else
            return hitEndThumb;
    } else if (hitStartThumb)
        return hitStartThumb;
    else if (hitEndThumb)
        return hitEndThumb;
    
    // We also want our autocomplete view to receive touches even when it's outside our view
    for (UIView *subview in [self subviews]) {
        if (subview == startThumb || subview == endThumb)
            continue; // We just tested these
        
        CGPoint pointInSubview = [self convertPoint:point toView:subview];
        UIView *hitView = [subview hitTest:pointInSubview withEvent:event];
        if (hitView) {
            return hitView;
        }
    }
    
    // But by default, use our superclass's behavior
    return [super hitTest:point withEvent:event];
}

static BOOL _eventTouchesView(UIEvent *event, UIView *view)
{
    if (view.hidden || !view.superview)
        return NO;
    
    if ([[event touchesForView:view] count] > 0)
        return YES;
    
    return NO;
}

- (BOOL)hasTouchesForEvent:(UIEvent *)event;
{
    // Thumbs extent outside our bounds, so check them too
    return _eventTouchesView(event, self) || _eventTouchesView(event, startThumb) || _eventTouchesView(event, endThumb);
}

static BOOL _recognizerTouchedView(UIGestureRecognizer *recognizer, UIView *view)
{
    if (view.hidden || !view.superview)
        return NO;
    
    return CGRectContainsPoint(view.bounds, [recognizer locationInView:view]);
}

- (BOOL)hasTouchByGestureRecognizer:(UIGestureRecognizer *)recognizer;
{
    // Thumbs extent outside our bounds, so check them too
    return _recognizerTouchedView(recognizer, self) || _recognizerTouchedView(recognizer, startThumb) || _recognizerTouchedView(recognizer, endThumb);
}


//UIKIT_EXTERN NSString *const UITextInputTextFontKey;            // Key to a UIFont

-(IBAction) handleTapGesture:(UIGestureRecognizer *) sender
{
    CGPoint touchPoint = [sender locationInView:self];
//    if (!mOwner.backend->PointInSelMargin(touchPoint) && ![self isFirstResponder]) {
//        [self becomeFirstResponder];
//    }
    [self becomeFirstResponder];
    [self _hideContextMenu];
    mOwner.backend->SingleTap(touchPoint);
    if (_delegate != nil && [_delegate respondsToSelector:@selector(handleGesture:)]) {
        [_delegate handleGesture:sender];
    }
}

-(IBAction) handleLongPressGesture:(UIGestureRecognizer *) sender
{
    CGPoint touchPoint = [sender locationInView:self];
    
    if (mOwner.backend->PointInSelMargin(touchPoint)) {
        mOwner.backend->SingleTap(touchPoint); // Nothing to do
        return;
    }
    
    UIGestureRecognizerState state = sender.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        if (!_loupe) {
            _loupe = [[OUILoupeOverlay alloc] initWithFrame:[self frame]];
            [_loupe setSubjectView:self];
            [[[[self superview] superview] superview] addSubview:_loupe];
        }
        [self _hideContextMenu];
    }
    
    // We want to update the loupe's touch point before the mode, so that when it's brought on screen it doesn't animate distractingly out from some other location.
    _loupe.touchPoint = touchPoint;
    
    if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateBegan) {
        mOwner.backend->SingleTap(touchPoint);
    }
    
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        _loupe.mode = OUILoupeOverlayNone;
        [self _showContextMenu];
        return;
    }
    
    /* UITextView has two selection inspecting/altering modes: caret and range. If you have a caret, you get a round selection inspection that just alters the inspection point. If you have a range, then the end of the range that your tap is closest to is altered and a rectangular selection inspector is shown. The endpoint manipulation goes through OUEFTextThumb, so we're just dealing with caret adjustment here. */
    _loupe.mode = OUILoupeOverlayCircle;
}

-(IBAction) orientationChange: (id) sender
{
    dispatch_async( dispatch_get_main_queue(), ^{
        if (isContextMenuActive) {
            [self _hideContextMenu];
            [self _showContextMenu];
        }
    });
}

- (void) orientationDidChange: (NSNotification *) note
{
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(orientationChange:) userInfo:nil repeats:NO];
}

-(void)_hideContextMenu
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if ([menu isMenuVisible]) {
        [menu setMenuVisible:NO];
    }
    isContextMenuActive = NO;
}

-(void)_showContextMenu
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (![menu isMenuVisible] && [self isFirstResponder]) {
        int selstart = mOwner.backend->SelectionStart().Position();
        int selend = mOwner.backend->SelectionEnd().Position();
        
        PRectangle rect = mOwner.backend->RectangleFromRange(selstart, selend);
        Scintilla::Point p1 = mOwner.backend->LocationFromPosition(selstart);
        Scintilla::Point p2 = mOwner.backend->LocationFromPosition(selend);
        
        CGRect selectionRect = CGRectMake(p1.x, p1.y, MIN(p2.x - p1.x, rect.Width()),
                                       rect.Height());
        
        [menu setTargetRect:selectionRect inView:self];
        menu.menuItems = [NSArray arrayWithObject:selectMenuItem];
        [menu setMenuVisible:YES animated:YES];
    }
    isContextMenuActive = YES;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL amFirstResponder = [self isFirstResponder];
    BOOL isSelectionEmpty = [mOwner message:SCI_GETSELECTIONEMPTY];
    
    if (amFirstResponder && !isSelectionEmpty) {
        /* We don't want to animate thumb appearance/disappearance --- it's distracting */
        BOOL wereAnimationsEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        
        CGRect caretRect;
        
        if (!startThumb) {
            startThumb = [[OUITextThumb alloc] init];
            startThumb.isEndThumb = NO;
            startThumb.delegate = self;
            [[[self superview] superview] addSubview:startThumb];
        }
        
        int selstart = mOwner.backend->SelectionStart().Position();
        int selend = mOwner.backend->SelectionEnd().Position();
        
        Scintilla::Point p1 = mOwner.backend->LocationFromPosition(selstart);
        Scintilla::Point p2 = mOwner.backend->LocationFromPosition(selend);
        int height = (int)[mOwner message:SCI_TEXTHEIGHT];
        
        caretRect = CGRectMake(p1.x -1, p1.y, 1.25, height);
        
        if (CGRectIsNull(caretRect)) {
            // This doesn't make a lot of sense, but it can happen if the layout height is finite
            startThumb.hidden = YES;
        } else {
            [startThumb setCaretRectangle:caretRect];
            startThumb.hidden = NO;
        }
        
        if (!endThumb) {
            endThumb = [[OUITextThumb alloc] init];
            endThumb.isEndThumb = YES;
            endThumb.delegate = self;
            [[[self superview] superview] addSubview:endThumb];
        }
        
        caretRect = CGRectMake(p2.x -1, p2.y, 1.25, height);
        
        if (CGRectIsNull(caretRect)) {
            // This doesn't make a lot of sense, but it can happen if the layout height is finite
            endThumb.hidden = YES;
        } else {
            [endThumb setCaretRectangle:caretRect];
            endThumb.hidden = NO;
        }
        
        [UIView setAnimationsEnabled:wereAnimationsEnabled];
    } else {
        // Hide thumbs if we've got 'em
        if (startThumb) {
            startThumb.hidden = YES;
        }
        
        if (endThumb) {
            endThumb.hidden = YES;
        }
    }
}

-(void)_showLoupeAtPos:(int)selpos
{
    int height = (int)[mOwner message:SCI_TEXTHEIGHT];
    Scintilla::Point pp = mOwner.backend->LocationFromPosition(selpos);
    CGRect loupeCaret = CGRectMake(pp.x -1, pp.y, 1.25, height);
    double lscale = 22.0 / MAX(loupeCaret.size.height, 2.0);
    CGPoint touch;
    touch.x = loupeCaret.origin.x;
    touch.y = loupeCaret.origin.y + 0.5 * loupeCaret.size.height;
    
    _loupe.touchPoint = touch;
    _loupe.scale = lscale;
    _loupe.mode = OUILoupeOverlayRectangle;
}

- (void)tumbInspect:(OUITextThumb *)thumb
{
    if (!_loupe) {
        _loupe = [[OUILoupeOverlay alloc] initWithFrame:[self frame]];
        [_loupe setSubjectView:self];
        [[[[self superview] superview] superview] addSubview:_loupe];
    }
    
    int selpos;
    
    if ([thumb isEndThumb]) {
        selpos = mOwner.backend->SelectionEnd().Position();
    } else {
        selpos = mOwner.backend->SelectionStart().Position();
    }
    
    [self _hideContextMenu];
    [self _showLoupeAtPos:selpos];
}

- (void)thumbBegan:(OUITextThumb *)thumb;
{
    if (!_loupe) {
        _loupe = [[OUILoupeOverlay alloc] initWithFrame:[self frame]];
        [_loupe setSubjectView:self];
        [[[[self superview] superview] superview] addSubview:_loupe];
    }
    [self _hideContextMenu];
}

- (void)thumbMoved:(OUITextThumb *)thumb targetPosition:(CGPoint)pt;
{
    BOOL isSelectionEmpty = [mOwner message:SCI_GETSELECTIONEMPTY];

    if (!isSelectionEmpty) {
        
        int selstart = mOwner.backend->SelectionStart().Position();
        int selend = mOwner.backend->SelectionEnd().Position();
        
        SelectionPosition newPos = mOwner.backend->SPositionFromLocation(
            mOwner.backend->ConvertPoint(pt), false, false, false);
    
        if ([thumb isEndThumb]) {
            newPos = mOwner.backend->MovePositionOutsideChar(newPos, 1);
        } else {
            newPos = mOwner.backend->MovePositionOutsideChar(newPos, 0);
        }
        
        [self _showLoupeAtPos:newPos.Position()];
     
        if (thumb.isEndThumb) {
            [mOwner message:SCI_SETSELECTION wParam:selstart lParam:newPos.Position()];
        } else {
            [mOwner message:SCI_SETSELECTION wParam:newPos.Position() lParam:selend];
        }
        [self setNeedsLayout];
    }
}

- (void)thumbEnded:(OUITextThumb *)thumb normally:(BOOL)normalEnd;
{
    _loupe.mode = OUILoupeOverlayNone;
    [self _showContextMenu];
}

- (void)deleteBackward
{
    mOwner.backend->DeleteBackward();
}

- (void)insertText:(NSString *)text
{
    mOwner.backend->InsertText(text);
}

- (BOOL)hasText
{
    if ([mOwner getGeneralProperty:SCI_GETLENGTH] > 0)
        return YES;
    return NO;
}

-(BOOL) canBecomeFirstResponder
{
    return mOwner.isEditable;
}

- (BOOL) becomeFirstResponder
{
    BOOL didBecomeFirstResponder = [super becomeFirstResponder];
    
    if (didBecomeFirstResponder) {
        mOwner.backend->WndProc(SCI_SETFOCUS, 1, 0);
    }
    
    return didBecomeFirstResponder;
}

- (BOOL) resignFirstResponder
{
    [super resignFirstResponder];
    
    mOwner.backend->WndProc(SCI_SETFOCUS, 0, 0);
    
    if (startThumb) {
        [startThumb removeFromSuperview];
        startThumb.delegate = nil;
        [startThumb release];
        startThumb = nil;
    }
    
    if (endThumb) {
        [endThumb removeFromSuperview];
        endThumb.delegate = nil;
        [endThumb release];
        endThumb = nil;
    }
    
    if (_loupe) {
        [_loupe removeFromSuperview];
        [_loupe setSubjectView:nil];
        [_loupe release];
        _loupe = nil;
    }

    return YES;
}

- (void)drawScaledContent:(CGRect)rect;
{
    CGContextRef gc = UIGraphicsGetCurrentContext();
    if (!mOwner.backend->Draw(rect, gc)) {
#if DEBUG
        NSLog(@"-drawScaledContent: - paintAbadoned");
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay];
        });
    }
}

//--------------------------------------------------------------------------------------------------

- (BOOL) canUndo
{
  return mOwner.backend->CanUndo();
}

- (BOOL) canRedo
{
  return mOwner.backend->CanRedo();
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL retValue = NO;
    BOOL hasSelection = ![mOwner message:SCI_GETSELECTIONEMPTY];
    if ( action == @selector(cut:) || action == @selector(copy:) )
        retValue = hasSelection;
    else if (action == @selector(selectText:))
        retValue = !hasSelection;
    else
        retValue = [super canPerformAction:action withSender:sender];
    
    return retValue;
}

-(IBAction)selectText:(id)sender
{
#pragma unused(sender)
    mOwner.backend->SelectWord();
    [self setNeedsLayout];
    [self _showContextMenu];
}

- (void) cut: (id) sender
{
#pragma unused(sender)
    mOwner.backend->Cut();
}

- (void) copy: (id) sender
{
#pragma unused(sender)
    mOwner.backend->Copy();
}

- (void) paste: (id) sender
{
#pragma unused(sender)
    mOwner.backend->Paste();
}

//--------------------------------------------------------------------------------------------------

@end

//--------------------------------------------------------------------------------------------------

@implementation ScintillaView

@synthesize backend = mBackend;
@synthesize delegate = mDelegate;
@synthesize scrollView;

/**
 * ScintillaView is a composite control made from an NSView and an embedded NSView that is
 * used as canvas for the output (by the backend, using its CGContext), plus other elements
 * (scrollers, info bar).
 */

//--------------------------------------------------------------------------------------------------

/**
 * Initialize custom cursor.
 */
+ (void) initialize
{
  if (self == [ScintillaView class])
  {
    
  }
}

//--------------------------------------------------------------------------------------------------

/**
 * Specify the SCIContentView class. Can be overridden in a subclass to provide an SCIContentView subclass.
 */

+ (Class) contentViewClass
{
  return [SCIContentView class];
}

//--------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------

/**
 * Sends a new notification of the given type to the default notification center.
 */
- (void) sendNotification: (NSString*) notificationName
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center postNotificationName: notificationName object: self];
}

//--------------------------------------------------------------------------------------------------


/**
 * Method receives notifications from Scintilla (e.g. for handling clicks on the
 * folder margin or changes in the editor).
 * A delegate can be set to receive all notifications. If set no handling takes place here, except
 * for action pertaining to internal stuff (like the info bar).
 */
- (void) notification: (Scintilla::SCNotification*)scn
{
  // Parent notification. Details are passed as SCNotification structure.
  
  if (mDelegate != nil)
  {
    [mDelegate notification: scn];
//    if (scn->nmhdr.code != SCN_ZOOM && scn->nmhdr.code != SCN_UPDATEUI) /* semyonc */
//      return;
  }
  
  switch (scn->nmhdr.code)
  {
    case SCN_MARGINCLICK:
    {
      if (scn->margin == 2) {
          // Click on the folder margin. Toggle the current line if possible.
          long line = [self getGeneralProperty: SCI_LINEFROMPOSITION parameter: scn->position];
          [self setGeneralProperty: SCI_TOGGLEFOLD value: line];
      }
      break;
    }
          
    case SCN_MODIFIED:
    {
      // Decide depending on the modification type what to do.
      // There can be more than one modification carried by one notification.
      if (scn->modificationType & (SC_MOD_INSERTTEXT | SC_MOD_DELETETEXT))
          [self sendNotification: NSTextDidChangeNotification];
        
        if (scn->modificationType & SC_MOD_CONTAINER) {
            undoToken = scn->token;
        }
      break;
    }
    case SCN_UPDATEUI:
    {
      // Triggered whenever changes in the UI state need to be reflected.
      // These can be: caret changes, selection changes etc.
      [self sendNotification: SCIUpdateUINotification];
       if (scn->updated & (SC_UPDATE_SELECTION | SC_UPDATE_CONTENT)) {
          [mContent setNeedsLayout];
          [mContent _hideContextMenu];
          if (![self message:SCI_GETSELECTIONEMPTY])
               [mContent _showContextMenu];
          [self sendNotification: NSTextViewDidChangeSelectionNotification];
       }
      break;
    }
    case SCN_FOCUSOUT:
      [self sendNotification: NSTextDidEndEditingNotification];
      break;
    case SCN_FOCUSIN: // Nothing to do for now.
      break;
  }
}

- (uptr_t) getLastUndoToken
{
    return undoToken;
}

//--------------------------------------------------------------------------------------------------

/**
 * Initialization of the view. Used to setup a few other things we need.
 */

- (id) initWithFrame: (CGRect) frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    mContent = [[[[[self class] contentViewClass] alloc] initWithFrame:CGRectZero] autorelease];
    mContent.owner = self;

    // Initialize the scrollers but don't show them yet.
    // Pick an arbitrary size, just to make NSScroller selecting the proper scroller direction
    // (horizontal or vertical).
    CGRect scrollerRect = CGRectMake(0, 0, 100, 10);
    scrollView = [[[UIScrollView alloc] initWithFrame: scrollerRect] autorelease];
    scrollView.delegate = self;
    scrollView.directionalLockEnabled = YES;
    [scrollView addSubview:mContent];
    [scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview: scrollView];
      
    mBackend = new ScintillaCocoa(mContent, nil);

    // Establish a connection from the back end to this container so we can handle situations
    // which require our attention.
    mBackend->SetDelegate(self);
    
    // Setup a special indicator used in the editor to provide visual feedback for 
    // input composition, depending on language, keyboard etc.
    [self setColorProperty: SCI_INDICSETFORE parameter: INPUT_INDICATOR fromHTML: @"#FF0000"];
    [self setGeneralProperty: SCI_INDICSETUNDER parameter: INPUT_INDICATOR value: 1];
    [self setGeneralProperty: SCI_INDICSETSTYLE parameter: INPUT_INDICATOR value: INDIC_PLAIN];
    [self setGeneralProperty: SCI_INDICSETALPHA parameter: INPUT_INDICATOR value: 100];
      
    [self setGeneralProperty: SCI_SETWRAPMODE value:SC_WRAP_CHAR];
    //[self setColorProperty: SCI_SETSELBACK parameter: 0 fromHTML:@"#CFDCED"];
  }
  return self;
}


//--------------------------------------------------------------------------------------------------

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  delete mBackend;
  [super dealloc];
}

//--------------------------------------------------------------------------------------------------

- (void) applicationDidResignActive: (NSNotification *)note {
#pragma unused(note)
    mBackend->ActiveStateChanged(false);
}

//--------------------------------------------------------------------------------------------------

- (void) applicationDidBecomeActive: (NSNotification *)note {
#pragma unused(note)
    mBackend->ActiveStateChanged(true);
}

//--------------------------------------------------------------------------------------------------

/**
 * Used to position and size the parts of the editor (content, scrollers, info bar).
 */
- (void) positionSubViews
{
  CGSize size = [self frame].size;

  // Horizontal offset of the content. Almost always 0 unless the vertical scroller
  // is on the left side.
  CGFloat contentX = 0;
  CGRect scrollRect = {contentX, 0, size.width, size.height};

  if (!CGRectEqualToRect([scrollView frame], scrollRect)) {
    [scrollView setFrame: scrollRect];
  }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGPoint offset = scrollView.contentOffset;
    CGSize size = mContent.bounds.size;
    mContent.frame = CGRectMake(offset.x, offset.y,
                                size.width, size.height);
    mBackend->UpdateForScroll();
    [mContent _hideContextMenu];
    [mContent setNeedsDisplay];
}

-(void) keyboardWasShown
{
    mBackend->Resize();
    CGPoint pt = mBackend->GetCaretPosition();
    mBackend->WndProc(SCI_ENSUREVISIBLEENFORCEPOLICY, pt.y, 0);
    [mContent setNeedsDisplay];
}

-(void) keyboardWillBeHidden
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if ([menu isMenuVisible]) {
        [menu setMenuVisible:NO];
    }
    mBackend->Resize();
    [mContent setNeedsDisplay];
}


//--------------------------------------------------------------------------------------------------

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self positionSubViews];
    mBackend->Resize();
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef gc = UIGraphicsGetCurrentContext();
    CGContextSaveGState(gc);
    CGContextSetFillColorWithColor(gc, [UIColor whiteColor].CGColor);
    CGContextFillRect(gc, rect);
    CGContextRestoreGState(gc);
}

-(BOOL)endEditing:(BOOL)force
{
    return [super endEditing:force];
}


//--------------------------------------------------------------------------------------------------

/**
 * Getter for the currently selected text in raw form (no formatting information included).
 * If there is no text available an empty string is returned.
 */
- (NSString*) selectedString
{
  NSString *result = @"";
  
  const long length = mBackend->WndProc(SCI_GETSELTEXT, 0, 0);
  if (length > 0)
  {
    std::string buffer(length + 1, '\0');
    try
    {
      mBackend->WndProc(SCI_GETSELTEXT, length + 1, (sptr_t) &buffer[0]);
      
      result = [NSString stringWithUTF8String: buffer.c_str()];
    }
    catch (...)
    {
    }
  }
  
  return result;
}

//--------------------------------------------------------------------------------------------------

/**
 * Getter for the current text in raw form (no formatting information included).
 * If there is no text available an empty string is returned.
 */
- (NSString*) text
{
  NSString *result = @"";
  
  const long length = mBackend->WndProc(SCI_GETLENGTH, 0, 0);
  if (length > 0)
  {
    std::string buffer(length + 1, '\0');
    try
    {
      mBackend->WndProc(SCI_GETTEXT, length + 1, (sptr_t) &buffer[0]);
      
      result = [NSString stringWithUTF8String: buffer.c_str()];
    }
    catch (...)
    {
    }
  }
  
  return result;
}

//--------------------------------------------------------------------------------------------------

/**
 * Setter for the current text (no formatting included).
 */
- (void) setText: (NSString*) aString
{
  const char* text = [aString UTF8String];
  mBackend->WndProc(SCI_SETTEXT, 0, (long) text);
}

//--------------------------------------------------------------------------------------------------

- (void) insertString: (NSString*) aString atOffset: (int)offset
{
  const char* text = [aString UTF8String];
  mBackend->WndProc(SCI_ADDTEXT, offset, (long) text);
}

//--------------------------------------------------------------------------------------------------

- (void) setEditable: (BOOL) editable
{
  mBackend->WndProc(SCI_SETREADONLY, editable ? 0 : 1, 0);
}

//--------------------------------------------------------------------------------------------------

- (BOOL) isEditable
{
  return mBackend->WndProc(SCI_GETREADONLY, 0, 0) == 0;
}

//--------------------------------------------------------------------------------------------------

- (SCIContentView*) content
{
  return mContent;
}

//--------------------------------------------------------------------------------------------------

/**
 * Direct call into the backend to allow uninterpreted access to it. The values to be passed in and
 * the result heavily depend on the message that is used for the call. Refer to the Scintilla
 * documentation to learn what can be used here.
 */
+ (sptr_t) directCall: (ScintillaView*) sender message: (unsigned int) message wParam: (uptr_t) wParam
               lParam: (sptr_t) lParam
{
  return ScintillaCocoa::DirectFunction(sender->mBackend, message, wParam, lParam);
}

- (sptr_t) message: (unsigned int) message wParam: (uptr_t) wParam lParam: (sptr_t) lParam
{
  return mBackend->WndProc(message, wParam, lParam);
}

- (sptr_t) message: (unsigned int) message wParam: (uptr_t) wParam
{
  return mBackend->WndProc(message, wParam, 0);
}

- (sptr_t) message: (unsigned int) message
{
  return mBackend->WndProc(message, 0, 0);
}

//--------------------------------------------------------------------------------------------------

/**
 * This is a helper method to set properties in the backend, with native parameters.
 *
 * @param property Main property like SCI_STYLESETFORE for which a value is to be set.
 * @param parameter Additional info for this property like a parameter or index.
 * @param value The actual value. It depends on the property what this parameter means.
 */
- (void) setGeneralProperty: (int) property parameter: (long) parameter value: (long) value
{
  mBackend->WndProc(property, parameter, value);
}

//--------------------------------------------------------------------------------------------------

/**
 * A simplified version for setting properties which only require one parameter.
 *
 * @param property Main property like SCI_STYLESETFORE for which a value is to be set.
 * @param value The actual value. It depends on the property what this parameter means.
 */
- (void) setGeneralProperty: (int) property value: (long) value
{
  mBackend->WndProc(property, value, 0);
}

//--------------------------------------------------------------------------------------------------

/**
 * This is a helper method to get a property in the backend, with native parameters.
 *
 * @param property Main property like SCI_STYLESETFORE for which a value is to get.
 * @param parameter Additional info for this property like a parameter or index.
 * @param extra Yet another parameter if needed.
 * @result A generic value which must be interpreted depending on the property queried.
 */
- (long) getGeneralProperty: (int) property parameter: (long) parameter extra: (long) extra
{
  return mBackend->WndProc(property, parameter, extra);
}

//--------------------------------------------------------------------------------------------------

/**
 * Convenience function to avoid unneeded extra parameter.
 */
- (long) getGeneralProperty: (int) property parameter: (long) parameter
{
  return mBackend->WndProc(property, parameter, 0);
}

//--------------------------------------------------------------------------------------------------

/**
 * Convenience function to avoid unneeded parameters.
 */
- (long) getGeneralProperty: (int) property
{
  return mBackend->WndProc(property, 0, 0);
}

//--------------------------------------------------------------------------------------------------

/**
 * Use this variant if you have to pass in a reference to something (e.g. a text range).
 */
- (long) getGeneralProperty: (int) property ref: (const void*) ref
{
  return mBackend->WndProc(property, 0, (sptr_t) ref);  
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property setter for colors.
 */
- (void) setColorProperty: (int) property parameter: (long) parameter value: (UIColor*) value
{
  CGFloat r,g,b,a;
  const CGFloat* colors = CGColorGetComponents(value.CGColor);
  const size_t ncolor = CGColorGetNumberOfComponents(value.CGColor);
    switch (ncolor) {
        case 2:
            r = g = b = colors[0];
            a = colors[1];
            break;
            
        case 4:
            r = colors[0];
            g = colors[1];
            b = colors[2];
            a = colors[3];
            break;
            
        default:
            return;
    }
  long red = a * r * 255;
  long green = a * g * 255;
  long blue = a * b * 255;
  long color = (blue << 16) + (green << 8) + red;
  mBackend->WndProc(property, parameter, color);
}

//--------------------------------------------------------------------------------------------------

/**
 * Another color property setting, which allows to specify the color as string like in HTML
 * documents (i.e. with leading # and either 3 hex digits or 6).
 */
- (void) setColorProperty: (int) property parameter: (long) parameter fromHTML: (NSString*) fromHTML
{
  if ([fromHTML length] > 3 && [fromHTML characterAtIndex: 0] == '#')
  {
    bool longVersion = [fromHTML length] > 6;
    int index = 1;
    
    char value[3] = {0, 0, 0};
    value[0] = [fromHTML characterAtIndex: index++];
    if (longVersion)
      value[1] = [fromHTML characterAtIndex: index++];
    else
      value[1] = value[0];

    unsigned rawRed;
    [[NSScanner scannerWithString: [NSString stringWithUTF8String: value]] scanHexInt: &rawRed];

    value[0] = [fromHTML characterAtIndex: index++];
    if (longVersion)
      value[1] = [fromHTML characterAtIndex: index++];
    else
      value[1] = value[0];
    
    unsigned rawGreen;
    [[NSScanner scannerWithString: [NSString stringWithUTF8String: value]] scanHexInt: &rawGreen];

    value[0] = [fromHTML characterAtIndex: index++];
    if (longVersion)
      value[1] = [fromHTML characterAtIndex: index++];
    else
      value[1] = value[0];
    
    unsigned rawBlue;
    [[NSScanner scannerWithString: [NSString stringWithUTF8String: value]] scanHexInt: &rawBlue];

    long color = (rawBlue << 16) + (rawGreen << 8) + rawRed;
    mBackend->WndProc(property, parameter, color);
  }
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property getter for colors.
 */
- (UIColor*) getColorProperty: (int) property parameter: (long) parameter
{
  long color = mBackend->WndProc(property, parameter, 0);
  float red = (color & 0xFF) / 255.0;
  float green = ((color >> 8) & 0xFF) / 255.0;
  float blue = ((color >> 16) & 0xFF) / 255.0;
  UIColor* result = [UIColor colorWithRed: red green: green blue: blue alpha: 1];
  return result;
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property setter for references (pointers, addresses).
 */
- (void) setReferenceProperty: (int) property parameter: (long) parameter value: (const void*) value
{
  mBackend->WndProc(property, parameter, (sptr_t) value);
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property getter for references (pointers, addresses).
 */
- (const void*) getReferenceProperty: (int) property parameter: (long) parameter
{
  return (const void*) mBackend->WndProc(property, parameter, 0);
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property setter for string values.
 */
- (void) setStringProperty: (int) property parameter: (long) parameter value: (NSString*) value
{
  const char* rawValue = [value UTF8String];
  mBackend->WndProc(property, parameter, (sptr_t) rawValue);
}


//--------------------------------------------------------------------------------------------------

/**
 * Specialized property getter for string values.
 */
- (NSString*) getStringProperty: (int) property parameter: (long) parameter
{
  const char* rawValue = (const char*) mBackend->WndProc(property, parameter, 0);
  return [NSString stringWithUTF8String: rawValue];
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property setter for lexer properties, which are commonly passed as strings.
 */
- (void) setLexerProperty: (NSString*) name value: (NSString*) value
{
  const char* rawName = [name UTF8String];
  const char* rawValue = [value UTF8String];
  mBackend->WndProc(SCI_SETPROPERTY, (sptr_t) rawName, (sptr_t) rawValue);
}

//--------------------------------------------------------------------------------------------------

/**
 * Specialized property getter for references (pointers, addresses).
 */
- (NSString*) getLexerProperty: (NSString*) name
{
  const char* rawName = [name UTF8String];
  const char* result = (const char*) mBackend->WndProc(SCI_SETPROPERTY, (sptr_t) rawName, 0);
  return [NSString stringWithUTF8String: result];
}

//--------------------------------------------------------------------------------------------------

/**
 * Sets the notification callback
 */
- (void) registerNotifyCallback: (intptr_t) windowid value: (Scintilla::SciNotifyFunc) callback
{
	mBackend->RegisterNotifyCallback(windowid, callback);
}


//--------------------------------------------------------------------------------------------------

- (void)insertText: (NSString*)text
{
  mBackend->InsertText(text);
}

//--------------------------------------------------------------------------------------------------

/**
 * For backwards compatibility.
 */
- (BOOL) findAndHighlightText: (NSString*) searchText
                    matchCase: (BOOL) matchCase
                    wholeWord: (BOOL) wholeWord
                     scrollTo: (BOOL) scrollTo
                         wrap: (BOOL) wrap
{
  return [self findAndHighlightText: searchText
                          matchCase: matchCase
                          wholeWord: wholeWord
                           scrollTo: scrollTo
                               wrap: wrap
                          backwards: NO];
}

//--------------------------------------------------------------------------------------------------

/**
 * Searches and marks the first occurrence of the given text and optionally scrolls it into view.
 *
 * @result YES if something was found, NO otherwise.
 */
- (BOOL) findAndHighlightText: (NSString*) searchText
                    matchCase: (BOOL) matchCase
                    wholeWord: (BOOL) wholeWord
                     scrollTo: (BOOL) scrollTo
                         wrap: (BOOL) wrap
                    backwards: (BOOL) backwards
{
  int searchFlags= 0;
  if (matchCase)
    searchFlags |= SCFIND_MATCHCASE;
  if (wholeWord)
    searchFlags |= SCFIND_WHOLEWORD;

  int selectionStart = (int)[self getGeneralProperty: SCI_GETSELECTIONSTART parameter: 0];
  int selectionEnd = (int)[self getGeneralProperty: SCI_GETSELECTIONEND parameter: 0];
  
  // Sets the start point for the coming search to the beginning of the current selection.
  // For forward searches we have therefore to set the selection start to the current selection end
  // for proper incremental search. This does not harm as we either get a new selection if something
  // is found or the previous selection is restored.
  if (!backwards)
    [self getGeneralProperty: SCI_SETSELECTIONSTART parameter: selectionEnd];
  [self setGeneralProperty: SCI_SEARCHANCHOR value: 0];
  sptr_t result;
  const char* textToSearch = [searchText UTF8String];

  // The following call will also set the selection if something was found.
  if (backwards)
  {
    result = [ScintillaView directCall: self
                               message: SCI_SEARCHPREV
                                wParam: searchFlags
                                lParam: (sptr_t) textToSearch];
    if (result < 0 && wrap)
    {
      // Try again from the end of the document if nothing could be found so far and
      // wrapped search is set.
      [self getGeneralProperty: SCI_SETSELECTIONSTART parameter: [self getGeneralProperty: SCI_GETTEXTLENGTH parameter: 0]];
      [self setGeneralProperty: SCI_SEARCHANCHOR value: 0];
      result = [ScintillaView directCall: self
                                 message: SCI_SEARCHNEXT
                                  wParam: searchFlags
                                  lParam: (sptr_t) textToSearch];
    }
  }
  else
  {
    result = [ScintillaView directCall: self
                               message: SCI_SEARCHNEXT
                                wParam: searchFlags
                                lParam: (sptr_t) textToSearch];
    if (result < 0 && wrap)
    {
      // Try again from the start of the document if nothing could be found so far and
      // wrapped search is set.
      [self getGeneralProperty: SCI_SETSELECTIONSTART parameter: 0];
      [self setGeneralProperty: SCI_SEARCHANCHOR value: 0];
      result = [ScintillaView directCall: self
                                 message: SCI_SEARCHNEXT
                                  wParam: searchFlags
                                  lParam: (sptr_t) textToSearch];
    }
  }

  if (result >= 0)
  {
    if (scrollTo)
      [self setGeneralProperty: SCI_SCROLLCARET value: 0];
  }
  else
  {
    // Restore the former selection if we did not find anything.
    [self setGeneralProperty: SCI_SETSELECTIONSTART value: selectionStart];
    [self setGeneralProperty: SCI_SETSELECTIONEND value: selectionEnd];
  }
  return (result >= 0) ? YES : NO;
}

//--------------------------------------------------------------------------------------------------

/**
 * Searches the given text and replaces
 *
 * @result Number of entries replaced, 0 if none.
 */
- (int) findAndReplaceText: (NSString*) searchText
                    byText: (NSString*) newText
                 matchCase: (BOOL) matchCase
                 wholeWord: (BOOL) wholeWord
                     doAll: (BOOL) doAll
{
  // The current position is where we start searching for single occurrences. Otherwise we start at
  // the beginning of the document.
  int startPosition;
  if (doAll)
    startPosition = 0; // Start at the beginning of the text if we replace all occurrences.
  else
    // For a single replacement we start at the current caret position.
    startPosition = (int)[self getGeneralProperty: SCI_GETCURRENTPOS];
  int endPosition = (int)[self getGeneralProperty: SCI_GETTEXTLENGTH];

  int searchFlags= 0;
  if (matchCase)
    searchFlags |= SCFIND_MATCHCASE;
  if (wholeWord)
    searchFlags |= SCFIND_WHOLEWORD;
  [self setGeneralProperty: SCI_SETSEARCHFLAGS value: searchFlags];
  [self setGeneralProperty: SCI_SETTARGETSTART value: startPosition];
  [self setGeneralProperty: SCI_SETTARGETEND value: endPosition];

  const char* textToSearch = [searchText UTF8String];
  size_t sourceLength = strlen(textToSearch); // Length in bytes.
  const char* replacement = [newText UTF8String];
  size_t targetLength = strlen(replacement);  // Length in bytes.
  sptr_t result;
  
  int replaceCount = 0;
  if (doAll)
  {
    while (true)
    {
      result = [ScintillaView directCall: self
                                 message: SCI_SEARCHINTARGET
                                  wParam: sourceLength
                                  lParam: (sptr_t) textToSearch];
      if (result < 0)
        break;

      replaceCount++;
      [ScintillaView directCall: self
                                 message: SCI_REPLACETARGET
                                  wParam: targetLength
                                  lParam: (sptr_t) replacement];

      // The replacement changes the target range to the replaced text. Continue after that till the end.
      // The text length might be changed by the replacement so make sure the target end is the actual
      // text end.
      [self setGeneralProperty: SCI_SETTARGETSTART value: [self getGeneralProperty: SCI_GETTARGETEND]];
      [self setGeneralProperty: SCI_SETTARGETEND value: [self getGeneralProperty: SCI_GETTEXTLENGTH]];
    }
  }
  else
  {
    result = [ScintillaView directCall: self
                               message: SCI_SEARCHINTARGET
                                wParam: sourceLength
                                lParam: (sptr_t) textToSearch];
    replaceCount = (result < 0) ? 0 : 1;

    if (replaceCount > 0)
    {
      [ScintillaView directCall: self
                                 message: SCI_REPLACETARGET
                                  wParam: targetLength
                                  lParam: (sptr_t) replacement];

    // For a single replace we set the new selection to the replaced text.
    [self setGeneralProperty: SCI_SETSELECTIONSTART value: [self getGeneralProperty: SCI_GETTARGETSTART]];
    [self setGeneralProperty: SCI_SETSELECTIONEND value: [self getGeneralProperty: SCI_GETTARGETEND]];
    }
  }
  
  return replaceCount;
}

//--------------------------------------------------------------------------------------------------

- (void) setFontName: (NSString*) font
                size: (int) size
                bold: (BOOL) bold
                italic: (BOOL) italic
{
  for (int i = 0; i < 128; i++)
  {
    [self setGeneralProperty: SCI_STYLESETFONT
                   parameter: i
                       value: (sptr_t)[font UTF8String]];
    [self setGeneralProperty: SCI_STYLESETSIZE
                   parameter: i
                       value: size];
    [self setGeneralProperty: SCI_STYLESETBOLD
                   parameter: i
                       value: bold];
    [self setGeneralProperty: SCI_STYLESETITALIC
                   parameter: i
                       value: italic];
  }
}

//--------------------------------------------------------------------------------------------------

@end

