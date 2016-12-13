//
//  ViewController.m
//  BluetoothTest
//
//  Created by ly on 16/7/4.
//  Copyright © 2016年 ly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <CommonCrypto/CommonDigest.h>

#import "NSDateHelper.h"

//write demo
static NSString * const kServiceUUID = @"FFE0";
static NSString * const kCharacteristicUUID = @"FFE1";
#define SERVICE_UUID     0xFFE0
#define CHAR_UUID        0xFFE1

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, retain) CBCentralManager *mgr;//中心设备管理者
@property (nonatomic, retain) CBPeripheral *myPeripheral;//选中的外设
@property (nonatomic, retain) CBService *service;//服务
@property (nonatomic, retain) CBCharacteristic *characteristic;//特征
@property (nonatomic, retain) NSArray *doorArray;
@end

@implementation ViewController

- (NSArray *)doorArray{
    if (!_doorArray){
        _doorArray = [NSArray arrayWithObjects:@"rYLTdl8cEUn0x1jH", @"hRDs6uXcWkUx5KSU", @"AyLbIoIAxESIFaJ4", @"KnxL2uHPiZLYf8t2",
                      @"gsQTGUC5Esc4hhvF", @"VEHh0rWNw20L2Js8", @"7FgEevVryWDpHXzq", @"lth55oTh6fFL2jZo", @"LoRpYZMl85CHVytl",
                      @"2VOYAkfOB1ZoeYNd", @"qgkwTZjdfwVzZFl9", @"FG3BHrtZZoKUoArB", @"5LjSFeOZCTz8Ffse", @"KB2okpE6v95B1MwM",
                      @"pOpi1Q63WHCoGdwu", @"teFuwVYW29uJtXV6", @"PZO68GWtUxWTnD49", @"BEyDyurtW9FCiUfk", @"fKccW5JMF4ISz82b",
                      @"a3ajkVGxOz4DQpt2",nil];
    }
    return _doorArray;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)openDoor {
    
    //创建中心管理者，管理中心设备
    self.mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [self cleanup];
    //开始搜索蓝牙设备
    [self.mgr scanForPeripheralsWithServices:nil options:nil];
    
}

#pragma mark - 清理蓝牙
//清理缓存
- (void)cleanup
{
    
    if (!self.myPeripheral) {
        return;
    }
    
    if (self.myPeripheral.state==CBPeripheralStateDisconnected||self.myPeripheral.state == CBPeripheralStateConnecting)
    {
        self.myPeripheral=nil;
        self.characteristic = nil;
        return;
    }
    
    if (self.service != nil&&self.characteristic!=nil)
    {
        if (self.characteristic.isNotifying)
        {
            [self.myPeripheral setNotifyValue:NO forCharacteristic:self.characteristic];
        }
    }
    
    [self.mgr cancelPeripheralConnection:self.myPeripheral];
    
    [self.mgr stopScan];
    
    self.myPeripheral=nil;
    self.service=nil;
    self.characteristic=nil;
}

#pragma mark - CBCentralManagerDelegate
//设备蓝牙状态更新
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    switch (central.state) {
        case CBCentralManagerStateUnsupported:
            NSLog(@"该设备不支持BLE蓝牙");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"该设备未授权BLE蓝牙");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"该设备BLE蓝牙已关闭");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"该设备BLE蓝牙发生未知错误");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"该设备BLE蓝牙重置中");
            break;
        case CBCentralManagerStatePoweredOn:
            [self cleanup];
            [self.mgr scanForPeripheralsWithServices:nil options:nil];
            break;
            
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

//发现外部设备时候调用此方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *periName = peripheral.name;
    
    self.myPeripheral = peripheral;
    //连接设备
    [self.mgr connectPeripheral:self.myPeripheral options:nil];
    //停止扫描蓝牙
    [self.mgr stopScan];
}

//连接蓝牙成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //发现服务
    self.myPeripheral .delegate = self;
    [self.myPeripheral  discoverServices:nil];
}

//连接蓝牙失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString *err = [NSString stringWithFormat:@"连接蓝牙门禁%@失败,原因:%@",peripheral.name,[error localizedDescription]];
    NSLog(@"%@",err);
}

//断开蓝牙连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
}


#pragma mark - CBPeripheralDelegate
//外设已经查找到服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) return; //发现服务失败
    
    //遍历所有服务
    for (CBService *service in self.myPeripheral.services) {
        NSLog(@"%@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]){
            self.service = service;
            break;
        }
    }
    
    if (self.service) {
        
        [self.myPeripheral discoverCharacteristics:nil forService:self.service];
    }
    
}

#pragma mark 找到特征时调用

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) return; //发现特征失败
    
    for (CBCharacteristic *characteristic in self.service.characteristics)
    {
        NSLog(@"%@",characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]])
        {
            self.characteristic = characteristic;
            //对此特征设置通知和读取返回数据
            [self.myPeripheral setNotifyValue:YES forCharacteristic:self.characteristic];
            [self.myPeripheral readValueForCharacteristic:self.characteristic];
            [self sendMessageToBle];
            break;
        }
        
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
        return;
    } //发送数据失败
    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) return; //接收特征数据失败
    NSString *value = [[NSString alloc] initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    NSLog(@"value==============%@",value);//蓝牙返回的信息，需要对蓝牙设备做特殊处理才能按照一定的格式返回数据
    if ([[value lowercaseString] isEqualToString:@"success"]){
        
    }else if ([[value lowercaseString] isEqualToString:@"fail"]){
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) return; //开启特征数据返回通知失败
    
}

#pragma mark - 向蓝牙发送数据
- (void)sendMessageToBle{
    
    int index =  arc4random() % 20;
    NSString *doorcode = self.doorArray[index];
    
    NSString *dateStr1 = [NSDate stringFromDate:[NSDate date] withFormat:@"yyyyMMdd"];
    NSString *dateStr2 = [NSDate stringFromDate:[NSDate date] withFormat:@"MMddyyyy"];
    NSString *dateStr = [NSString stringWithFormat:@"%@%@",dateStr1,dateStr2];
    
    NSString *strA1 = @"OW15LjrCaY2bfcMl";
    NSString *strB1 = @"aWuK48JRDPePsYXE";
    
    Byte *A = [self strToByte:dateStr];
    Byte *A1 = [self strToByte:strA1];
    Byte *B = [self strToByte:doorcode];
    Byte *B1 = [self strToByte:strB1];
    
    Byte bleData[16] = {0};
    for (int i = 0; i < strA1.length; i ++) {
        Byte left = (Byte)(A[i] & A1[i]);
        Byte right = (Byte)(B[i] | B1[i]);
        bleData[i] = (Byte)(left ^ right);
    }
    Byte bleMD5[16] ={0};
    CC_MD5(bleData, 16, bleMD5);
    Byte final[15] = {0};
    final[0] = 15;
    for (int i = 0; i < 12; i ++) {
        final[i + 1] = bleMD5[i];
    }
    final[13] = 13;
    final[14] = 10;
    
    NSData *finalData = [NSData dataWithBytes:final length:15];
    
    [self writeValue:SERVICE_UUID characteristicUUID:CHAR_UUID p:self.myPeripheral data:finalData];
}

-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUIDEx:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
        return;
    }
    [p setNotifyValue:YES forCharacteristic:characteristic];
    if(characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse)
    {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else
    {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}
-(CBService *) findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}
-(const char *) UUIDToString:(CFUUIDRef)UUID {
    if (!UUID) return "NULL";
    CFStringRef s = CFUUIDCreateString(NULL, UUID);
    return CFStringGetCStringPtr(s, 0);
}

-(CBCharacteristic *) findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

//字符串转byte
- (Byte *)strToByte:(NSString *)strBefor{
    Byte *bt = (Byte *)malloc(16);
    for (int i =0; i < strBefor.length; i++) {
        int strInt = [strBefor characterAtIndex:i];
        Byte b =  (Byte) ((0xff & strInt) );//( Byte) 0xff&iByte;
        bt[i] = b;
    }
    return bt;
}

@end
