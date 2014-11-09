//
//  ViewController.mm
//  ScintillaContainer
//
//  Created by Semyon A. Chertkov on 31.10.13.
//  Copyright (c) 2013 Semyon A. Chertkov. All rights reserved.
//

#import "ViewController.h"
#import "ScintillaView.h"

const char major_keywords[] =
"accessible add all alter analyze and as asc asensitive "
"before between bigint binary blob both by "
"call cascade case change char character check collate column condition connection constraint "
"continue convert create cross current_date current_time current_timestamp current_user cursor "
"database databases day_hour day_microsecond day_minute day_second dec decimal declare default "
"delayed delete desc describe deterministic distinct distinctrow div double drop dual "
"each else elseif enclosed escaped exists exit explain "
"false fetch float float4 float8 for force foreign from fulltext "
"goto grant group "
"having high_priority hour_microsecond hour_minute hour_second "
"if ignore in index infile inner inout insensitive insert int int1 int2 int3 int4 int8 integer "
"interval into is iterate "
"join "
"key keys kill "
"label leading leave left like limit linear lines load localtime localtimestamp lock long "
"longblob longtext loop low_priority "
"master_ssl_verify_server_cert match mediumblob mediumint mediumtext middleint minute_microsecond "
"minute_second mod modifies "
"natural not no_write_to_binlog null numeric "
"on optimize option optionally or order out outer outfile "
"precision primary procedure purge "
"range read reads read_only read_write real references regexp release rename repeat replace "
"require restrict return revoke right rlike "
"schema schemas second_microsecond select sensitive separator set show smallint spatial specific "
"sql sqlexception sqlstate sqlwarning sql_big_result sql_calc_found_rows sql_small_result ssl "
"starting straight_join "
"table terminated then tinyblob tinyint tinytext to trailing trigger true "
"undo union unique unlock unsigned update upgrade usage use using utc_date utc_time utc_timestamp "
"values varbinary varchar varcharacter varying "
"when where while with write "
"xor "
"year_month "
"zerofill";

const char procedure_keywords[] = // Not reserved words but intrinsic part of procedure definitions.
"begin comment end";

const char client_keywords[] = // Definition of keywords only used by clients, not the server itself.
"delimiter";

const char user_keywords[] = // Definition of own keywords, not used by MySQL.
"edit";


@interface ViewController ()
{
    ScintillaView *editor;
    BOOL keyboardShown;
    CGSize keyboardSize;
    CGSize offset;
    UIDeviceOrientation orientationAtShown;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = self.view.frame;
    frame.origin.y += 20;
    frame.size.height -= 20;
   	editor = [[ScintillaView alloc] initWithFrame:frame];
    editor.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self loadContent];
    [self setupEditor];
    [self.view addSubview:editor];
    [self registerForKeyboardNotifications];
}


// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0,
                                                  UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ?
                                                  kbSize.width : kbSize.height, 0.0);
    editor.scrollView.contentInset = contentInsets;
    editor.scrollView.scrollIndicatorInsets = contentInsets;
    [editor keyboardWasShown];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    editor.scrollView.contentInset = contentInsets;
    editor.scrollView.scrollIndicatorInsets = contentInsets;
    [editor keyboardWillBeHidden];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) fillContent
{
    NSMutableString *str = [NSMutableString stringWithCapacity:1024];
    for (int i = 0; i < 100; i++) {
        if (i > 0)
            [str appendString:@"\n"];
        [str appendFormat:@"Line %d", i + 1];
    }
    editor.text = str;
}

- (void) loadContent
{
    // Let's load some text for the editor, as initial content.
    NSError* error = nil;
    
    NSString* path = [[NSBundle mainBundle] pathForResource: @"TestData"
                                                     ofType: @"sql" inDirectory: nil];
    
    NSString* sql = [NSString stringWithContentsOfFile: path
                                              encoding: NSUTF8StringEncoding
                                                 error: &error];
    if (error && [[error domain] isEqual: NSCocoaErrorDomain])
        NSLog(@"%@", error);
    
    [editor setText: sql];
}

- (void) shortSetup
{
    [editor setColorProperty: SCI_STYLESETFORE parameter: STYLE_LINENUMBER fromHTML: @"#F0F0F0"];
    [editor setColorProperty: SCI_STYLESETBACK parameter: STYLE_LINENUMBER fromHTML: @"#808080"];
    [editor setGeneralProperty: SCI_SETMARGINTYPEN parameter: 0 value: SC_MARGIN_NUMBER];
	[editor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 0 value: 35];
    [editor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 1 value: 16];
    [editor setGeneralProperty: SCI_SETMARGINMASKN parameter: 1 value: SC_MASK_FOLDERS];
    [editor setGeneralProperty: SCI_SETMARGINSENSITIVEN parameter: 1 value: 1];
}

- (void) setupEditor
{
    // Lexer type is MySQL.
    [editor setGeneralProperty: SCI_SETLEXER parameter: SCLEX_MYSQL value: 0];
    // alternatively: [editor setEditorProperty: SCI_SETLEXERLANGUAGE parameter: nil value: (sptr_t) "mysql"];
    
    // Number of styles we use with this lexer.
    [editor setGeneralProperty: SCI_SETSTYLEBITS value: [editor getGeneralProperty: SCI_GETSTYLEBITSNEEDED]];
    
    // Keywords to highlight. Indices are:
    // 0 - Major keywords (reserved keywords)
    // 1 - Normal keywords (everything not reserved but integral part of the language)
    // 2 - Database objects
    // 3 - Function keywords
    // 4 - System variable keywords
    // 5 - Procedure keywords (keywords used in procedures like "begin" and "end")
    // 6..8 - User keywords 1..3
    [editor setReferenceProperty: SCI_SETKEYWORDS parameter: 0 value: major_keywords];
    [editor setReferenceProperty: SCI_SETKEYWORDS parameter: 5 value: procedure_keywords];
    [editor setReferenceProperty: SCI_SETKEYWORDS parameter: 6 value: client_keywords];
    [editor setReferenceProperty: SCI_SETKEYWORDS parameter: 7 value: user_keywords];
    
    // Colors and styles for various syntactic elements. First the default style.
    [editor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Helvetica"];
    // [editor setStringProperty: SCI_STYLESETFONT parameter: STYLE_DEFAULT value: @"Monospac821 BT"]; // Very pleasing programmer's font.
    [editor setGeneralProperty: SCI_STYLESETSIZE parameter: STYLE_DEFAULT value: 14];
    [editor setColorProperty: SCI_STYLESETFORE parameter: STYLE_DEFAULT value: [UIColor blackColor]];
    
    [editor setGeneralProperty: SCI_STYLECLEARALL parameter: 0 value: 0];
    
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DEFAULT value: [UIColor blackColor]];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_COMMENT fromHTML: @"#097BF7"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_COMMENTLINE fromHTML: @"#097BF7"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_HIDDENCOMMAND fromHTML: @"#097BF7"];
    [editor setColorProperty: SCI_STYLESETBACK parameter: SCE_MYSQL_HIDDENCOMMAND fromHTML: @"#F0F0F0"];
    
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_VARIABLE fromHTML: @"378EA5"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_SYSTEMVARIABLE fromHTML: @"378EA5"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_KNOWNSYSTEMVARIABLE fromHTML: @"#3A37A5"];
    
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_NUMBER fromHTML: @"#7F7F00"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_SQSTRING fromHTML: @"#FFAA3E"];
    
    // Note: if we were using ANSI quotes we would set the DQSTRING to the same color as the
    //       the back tick string.
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DQSTRING fromHTML: @"#274A6D"];
    
    // Keyword highlighting.
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_MAJORKEYWORD fromHTML: @"#007F00"];
    [editor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_MAJORKEYWORD value: 1];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_KEYWORD fromHTML: @"#007F00"];
    [editor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_KEYWORD value: 1];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_PROCEDUREKEYWORD fromHTML: @"#56007F"];
    [editor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_MYSQL_PROCEDUREKEYWORD value: 1];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_USER1 fromHTML: @"#808080"];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_USER2 fromHTML: @"#808080"];
    [editor setColorProperty: SCI_STYLESETBACK parameter: SCE_MYSQL_USER2 fromHTML: @"#F0E0E0"];
    
    // The following 3 styles have no impact as we did not set a keyword list for any of them.
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_DATABASEOBJECT value: [UIColor redColor]];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_FUNCTION value: [UIColor redColor]];
    
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_IDENTIFIER value: [UIColor blackColor]];
    [editor setColorProperty: SCI_STYLESETFORE parameter: SCE_MYSQL_QUOTEDIDENTIFIER fromHTML: @"#274A6D"];
    [editor setGeneralProperty: SCI_STYLESETBOLD parameter: SCE_SQL_OPERATOR value: 1];
    
    // Line number style.
    [editor setColorProperty: SCI_STYLESETFORE parameter: STYLE_LINENUMBER fromHTML: @"#F0F0F0"];
    [editor setColorProperty: SCI_STYLESETBACK parameter: STYLE_LINENUMBER fromHTML: @"#808080"];
    
    [editor setGeneralProperty: SCI_SETMARGINTYPEN parameter: 0 value: SC_MARGIN_NUMBER];
	[editor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 0 value: 35];
    
    // Markers.
    [editor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 1 value: 16];
    
    // Some special lexer properties.
    [editor setLexerProperty: @"fold" value: @"1"];
    [editor setLexerProperty: @"fold.compact" value: @"0"];
    [editor setLexerProperty: @"fold.comment" value: @"1"];
    [editor setLexerProperty: @"fold.preprocessor" value: @"1"];
    
    // Folder setup.
    [editor setGeneralProperty: SCI_SETMARGINWIDTHN parameter: 2 value: 16];
    [editor setGeneralProperty: SCI_SETMARGINMASKN parameter: 2 value: SC_MASK_FOLDERS];
    [editor setGeneralProperty: SCI_SETMARGINSENSITIVEN parameter: 2 value: 1];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPEN value: SC_MARK_BOXMINUS];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDER value: SC_MARK_BOXPLUS];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERSUB value: SC_MARK_VLINE];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERTAIL value: SC_MARK_LCORNER];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEREND value: SC_MARK_BOXPLUSCONNECTED];
    [editor setGeneralProperty: SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDEROPENMID value: SC_MARK_BOXMINUSCONNECTED];
    [editor setGeneralProperty
     : SCI_MARKERDEFINE parameter: SC_MARKNUM_FOLDERMIDTAIL value: SC_MARK_TCORNER];
    for (int n= 25; n < 32; ++n) // Markers 25..31 are reserved for folding.
    {
        [editor setColorProperty: SCI_MARKERSETFORE parameter: n value: [UIColor whiteColor]];
        [editor setColorProperty: SCI_MARKERSETBACK parameter: n value: [UIColor blackColor]];
    }
    
    // Init markers & indicators for highlighting of syntax errors.
    [editor setColorProperty: SCI_INDICSETFORE parameter: 0 value: [UIColor redColor]];
    [editor setGeneralProperty: SCI_INDICSETUNDER parameter: 0 value: 1];
    [editor setGeneralProperty: SCI_INDICSETSTYLE parameter: 0 value: INDIC_SQUIGGLE];
    
    [editor setColorProperty: SCI_MARKERSETBACK parameter: 0 fromHTML: @"#B1151C"];
    
    //[editor setColorProperty: SCI_SETSELBACK parameter: 1 value: [UIColor selectedTextBackgroundColor]];
}


@end
