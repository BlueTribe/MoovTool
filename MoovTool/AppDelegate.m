#import "AppDelegate.h"
#import "MoovInterface.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSComboBox * chooserBox;
@property (weak) IBOutlet NSButton * connectButton;
@property (weak) IBOutlet NSButton * startRecordButton;
@property (weak) IBOutlet NSButton * readDataButton;
@property (weak) IBOutlet NSTextField * resultField;

- (IBAction)chooseAction:(id)sender;

@end

@implementation AppDelegate
static MoovInterface * mi;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    mi = [[MoovInterface alloc] init];
    self.chooserBox.usesDataSource = YES;
    self.chooserBox.dataSource = self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

////////////////////////////////////////////////////////////////////////////////////////////
// Combo Box
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return mi.peripherals.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return ((CBPeripheral*)mi.peripherals[index]).name;
}

- (void)update
{
    if(mi.peripherals.count > 0)
    {
        [self.chooserBox setEnabled: YES];
    }
    
    if(CBPeripheralStateConnected == mi.moov.state)
    {
        [self.startRecordButton setEnabled:YES];
        [self.readDataButton setEnabled:YES];

        if(mi.readValue)
        {
            [self.resultField setStringValue: mi.readValue.description];
        }
    }
}

- (IBAction)chooseAction:(id)sender;
{
    moovNdx = ((NSComboBox *)sender).indexOfSelectedItem;
    [self.connectButton setEnabled: YES];
}

////////////////////////////////////////////////////////////////////////////////////////////
// Buttons
- (IBAction)connect:(id)sender
{
    [mi connect: moovNdx];
}

- (IBAction)startRecord:(id)sender
{
    [mi record];
}

- (IBAction)readData:(id)sender
{
    [mi read];
}

@end
