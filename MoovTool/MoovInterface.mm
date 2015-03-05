#import "MoovInterface.h"
#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>

#define MOOV_ADV_SERVICE_UUID @"2B0A857D-3982-4152-B46F-5E7423578524"
#define MOOV_MEM_SERVICE_UUID @"f000cd50-0451-4000-b000-000000000000"

#define MOOV_ADDR_CHAR_UUID @"f000cd61-0451-4000-b000-000000000000"
#define MOOV_MEM_READ_CHAR_UUID @"f000cd62-0451-4000-b000-000000000000"

@implementation MoovInterface

-(id)init
{
    self = [super init];
    
    cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    self.peripherals = [[NSMutableArray alloc] init];
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////
// Device Functions
-(void)connect: (NSInteger)ndx
{
    self.moov = self.peripherals[ndx];
    
    if(self.moov)
    {
        [cbManager connectPeripheral:self.moov options:nil];
    }
}

-(void)record
{
    // Todo
}

-(void)read
{
    if(self.moov)
    {
        [self.moov readValueForCharacteristic:readChar];
    }
}
// Device Functions
////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////
// Central Manager Delegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            [cbManager scanForPeripheralsWithServices: @[[CBUUID UUIDWithString: MOOV_ADV_SERVICE_UUID]]
                                              options: @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
        break;
            
        default:
            NSLog(@"Central State: %ld", central.state);
        break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", peripheral);
    [central stopScan];
    [self.peripherals addObject:peripheral];
    
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected %@", peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices: @[[CBUUID UUIDWithString: MOOV_MEM_SERVICE_UUID]]];
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect %@ Error %@", peripheral, error);
}

// Central Manager Delegate
////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////
// Peripheral Manager Delegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    CBService * service;
    
    for (service in peripheral.services)
    {
        NSLog(@"Discovered Service: %@", service.UUID);
        
        if([service.UUID isEqualTo: [CBUUID UUIDWithString:MOOV_MEM_SERVICE_UUID]])
        {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:MOOV_ADDR_CHAR_UUID],
                                                  [CBUUID UUIDWithString:MOOV_MEM_READ_CHAR_UUID]]
                                     forService: service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    CBCharacteristic * characteristic;
    
    for(characteristic in service.characteristics)
    {
        NSLog(@"Discovered Characteristic: %@", characteristic.UUID);
        if([characteristic.UUID isEqualTo:[CBUUID UUIDWithString:MOOV_MEM_READ_CHAR_UUID]])
        {
            readChar = characteristic;
            // tell the app delegate something changed
            [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
        }
        else if([characteristic.UUID isEqualTo:[CBUUID UUIDWithString:MOOV_ADDR_CHAR_UUID]])
        {
            addrChar = characteristic;
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Read Value %@", characteristic.value);
    self.readValue = characteristic.value;
    
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}
// Peripheral Manager Delegate
////////////////////////////////////////////////////////////////////////////////////////////

@end
