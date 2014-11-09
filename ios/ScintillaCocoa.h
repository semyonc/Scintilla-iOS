/*
 * ScintillaCocoa.h
 *
 * Mike Lischke <mlischke@sun.com>
 *
 * Based on ScintillaMacOSX.h
 * Original code by Evan Jones on Sun Sep 01 2002.
 *  Contributors:
 *  Shane Caraveo, ActiveState
 *  Bernd Paradies, Adobe
 *
 * Copyright 2009 Sun Microsystems, Inc. All rights reserved.
 * This file is dual licensed under LGPL v2.1 and the Scintilla license (http://www.scintilla.org/License.txt).
 */

#include <stdlib.h>
#include <string>
#include <stdio.h>
#include <ctype.h>
#include <time.h>

#include <vector>
#include <map>

#include "ILexer.h"

#ifdef SCI_LEXER
#include "SciLexer.h"
#include "PropSetSimple.h"
#endif

#include "SplitVector.h"
#include "Partitioning.h"
#include "RunStyles.h"
#include "ContractionState.h"
#include "CellBuffer.h"
#include "CallTip.h"
#include "KeyMap.h"
#include "Indicator.h"
#include "XPM.h"
#include "LineMarker.h"
#include "Style.h"
#include "AutoComplete.h"
#include "ViewStyle.h"
#include "CharClassify.h"
#include "Decoration.h"
#include "CaseFolder.h"
#include "Document.h"
#include "Selection.h"
#include "PositionCache.h"
#include "Editor.h"

#include "ScintillaBase.h"
#include "CaseConvert.h"

extern "C" NSString* ScintillaRecPboardType;

@class SCIContentView;
@class SCIMarginView;
@class ScintillaView;

@class FindHighlightLayer;

/**
 * Helper class to be used as timer target (NSTimer).
 */
@interface TimerTarget : NSObject
{
  void* mTarget;
  NSNotificationQueue* notificationQueue;
}
- (id) init: (void*) target;
- (void) timerFired: (NSTimer*) timer;
- (void) idleTimerFired: (NSTimer*) timer;
- (void) idleTriggered: (NSNotification*) notification;
@end

namespace Scintilla {

/**
 * Main scintilla class, implemented for OS X (Cocoa).
 */
class ScintillaCocoa : public ScintillaBase
{
private:
  TimerTarget* timerTarget;
  UIEvent* lastMouseEvent;
  
  id<ScintillaNotificationProtocol> delegate;

  SciNotifyFunc	notifyProc;
  intptr_t notifyObj;

  bool capturedMouse;

  bool enteredSetScrollingSize;

  // Private so ScintillaCocoa objects can not be copied
  ScintillaCocoa(const ScintillaCocoa &) : ScintillaBase() {}
  ScintillaCocoa &operator=(const ScintillaCocoa &) { return * this; }

  bool GetPasteboardData(UIPasteboard* board, SelectionText* selectedText);
  void SetPasteboardData(UIPasteboard* board, const SelectionText& selectedText);
  
  int scrollSpeed;
  int scrollTicks;
  NSTimer* tickTimer;
  NSTimer* idleTimer;
  CFRunLoopObserverRef observer;
	
  FindHighlightLayer *layerFindIndicator;

protected:
  Point GetVisibleOriginInMain();
  PRectangle GetClientRectangle();
  
  virtual void Initialise();
  virtual void Finalise();
  virtual CaseFolder *CaseFolderForEncoding();
  virtual std::string CaseMapString(const std::string &s, int caseMapping);
  virtual void CancelModes();

public:
  ScintillaCocoa(SCIContentView* view, SCIMarginView* viewMargin);
  virtual ~ScintillaCocoa();

  Point ConvertPoint(CGPoint point);

  void SetDelegate(id<ScintillaNotificationProtocol> delegate_);
  void RegisterNotifyCallback(intptr_t windowid, SciNotifyFunc callback);
  sptr_t WndProc(unsigned int iMessage, uptr_t wParam, sptr_t lParam);

  ScintillaView* TopContainer();
  UIScrollView* ScrollContainer();
  SCIContentView* ContentView();

  bool SyncPaint(void* gc, PRectangle rc);
  bool Draw(CGRect rect, CGContextRef gc);
  void PaintMargin(CGRect aRect);

  virtual sptr_t DefWndProc(unsigned int iMessage, uptr_t wParam, sptr_t lParam);
  void SetTicking(bool on);
  bool SetIdle(bool on);
  void SetMouseCapture(bool on);
  bool HaveMouseCapture();
  void ScrollText(int linesToMove);
  void SetVerticalScrollPos();
  void SetHorizontalScrollPos();
  bool ModifyScrollBars(int nMax, int nPage);
  bool SetScrollingSize(void);
  void Resize();
  void UpdateForScroll();

  // Notifications for the owner.
  void NotifyChange();
  void NotifyFocus(bool focus);
  void NotifyParent(SCNotification scn);
  void NotifyURIDropped(const char *uri);

  bool HasSelection();
  bool CanUndo();
  bool CanRedo();
  virtual void CopyToClipboard(const SelectionText &selectedText);
  virtual void Copy();
  virtual bool CanPaste();
  virtual void Paste();
  virtual void Paste(bool rectangular);
  void CTPaint(void* gc, CGRect rc);
  void CallTipMouseDown(CGPoint pt);
  virtual void CreateCallTipWindow(PRectangle rc);
  virtual void AddToPopUp(const char *label, int cmd = 0, bool enabled = true);
  virtual void ClaimSelection();

  CGPoint GetCaretPosition();
  
  static sptr_t DirectFunction(ScintillaCocoa *sciThis, unsigned int iMessage, uptr_t wParam, sptr_t lParam);

  void TimerFired(NSTimer* timer);
  void IdleTimerFired();
  static void UpdateObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *sci);
  void ObserverAdd();
  void ObserverRemove();
  virtual void IdleWork();
  virtual void QueueIdleWork(WorkNeeded::workItems items, int upTo);
  int InsertText(NSString* input);
  void SelectOnlyMainSelection();
  virtual void SetDocPointer(Document *document);

  bool KeyboardInput(NSString* event);
  void SingleTap(CGPoint location);

  
  // Promote some methods needed for NSResponder actions.
  virtual void SelectAll();
  void DeleteBackward();
  virtual void Cut();
  virtual void Undo();
  virtual void Redo();
  
  void HandleCommand(NSInteger command);

  virtual void ActiveStateChanged(bool isActive);

  // Find indicator
  void ShowFindIndicatorForRange(NSRange charRange, BOOL retaining);
  void MoveFindIndicatorWithBounce(BOOL bounce);
  void HideFindIndicator();
    
  // semyonc
  CGRect GetScreenSelectLineRect();
    
  bool PointInSelMargin(CGPoint p);
};


}


