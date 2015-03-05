#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface MoovInterface : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager * cbManager;
    
    CBCharacteristic * addrChar;
    CBCharacteristic * readChar;
}

@property (strong,nonatomic) NSMutableArray *peripherals;
@property (strong,nonatomic) CBPeripheral *moov;
@property (strong,nonatomic) NSData * readValue;


-(void)connect: (NSInteger)ndx;
-(void)record;
-(void)read;

@end
