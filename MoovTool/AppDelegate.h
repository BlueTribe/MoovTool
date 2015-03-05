#import <Cocoa/Cocoa.h>
@class MoovInterface;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSComboBoxDataSource>
{
    NSInteger moovNdx;
}

-(void)update;
@end

