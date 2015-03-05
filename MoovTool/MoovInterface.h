#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface MoovInterface : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager * cbManager;
    CBCharacteristic * addrChar;
    CBCharacteristic * readChar;
}

@property (strong,nonatomic) NSMutableArray *peripherals;
@end
