/*
TAROGE-3 Power Control by Shih-Ying Hsu
*/

//#include <Relay_.h>
//Relay_ Relay(15);

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Setting the pin No. of the Forced-Bootup Button
const int Pin_FBB_o = 12;  //High
const int Pin_FBB_i = 13;  //Read

//Setting the temperature and humidity sensor
#include <Adafruit_Sensor.h>
#include <DHT_U.h>
#include <DHT.h>
const int Pin_DHT1 = 6;  //DHT22 sensor; 2017
const int Pin_DHT2 = 7;  //DHT22 sensor; 2017
#define DHTTYPE DHT22   // DHT 22  (AM2302)
DHT DHT1(Pin_DHT1, DHTTYPE); //// Initialize DHT sensor for normal 16mhz Arduino
DHT DHT2(Pin_DHT2, DHTTYPE); //// Initialize DHT sensor for normal 16mhz Arduino
float DHTData[]={0,0};
////

//Setting the PWM of the fans.
const int Pin_PWMFan1 = 9; //Taroge-3:  only pin 8, 9, 10 are available for PWM (otherwise occupied ); pin 9 = OC2B (B mode of Timer 2)
const int Pin_PWMFan2 = 10; //Taroge-3:  only pin 8, 9, 10 are available for PWM (otherwise occupied ); pin 9 = OC2B (B mode of Timer 2)
const unsigned long Wait_ms = 5000;

const short NFanMode = 3;
float Fan_TempLvUpper[NFanMode] = {25., 30. , 1000.}; //upper limit of each mode in degree C
//byte Fan_DutyCycle[NFanMode] = { 39, 39, 39 } ; //[0,79]: duty cycle =  x/80
double Fan_DutyCycle[NFanMode] = { 50., 50., 50. } ; //percentage [0, 100]
short FanMode = 0;


// Include these libraries for using the RS-232 and Modbus functions
//#include <RS232.h>
#include <ModbusMaster232.h>
#include <SPI.h>
// Instantiate ModbusMaster object as slave ID 1
ModbusMaster232 node(1);

// Define the number of bytes to read
#define bytesQty 2

// Define the number of the relays.
const int NRelay = 15;
int relayState[NRelay]; 

const int relayNo_PC = 0; //pin 22,23
const int relayNo_SCOPE1 = 1;
const int relayNo_SCOPE2 = 2;
const int relayNo_SCOPE3 = 3;
const int relayNo_LNA1= 4;
const int relayNo_LNA2 = 5;
const int relayNo_LNA3 = 6;
const int relayNo_FAN = 7;
const int relayNo_ROUTER = 8;
const int relayNo_TRGBRD = 10;
const int relayNo_EXTHDD = 11;
const int relayNo_OSC = 13;

const int relayNo_SPARE12V = 9;
const int relayNo_SPARE5V = 12;
const int relayNo_SPARE3V3 = 14;

// Define the house keeping data.
int MPPTDataCount = 278;

//2017 version, skip unwanted data; N=278 --> 110
const int NMPPTData = 110;
const int NMPPTBlock = 11; //for skipping unwanted data
const int NPerMPPTBlock[ NMPPTBlock ] = { 5, 56, 3, 12, 6, 6, 1, 2, 13, 4, 2};
const unsigned int MPPTBlockStartAddress[ NMPPTBlock ] = { 0x0000, 0x0018, 0x0059, 0xE000, 0xE00D, 0xE015, 0xE01D, 0xE020, 0xE080, 0xE0C0, 0xE0CC };
int MPPTData[NMPPTData]={};
int MPPTDataAddress[NMPPTData] = {};
//int MPPTData[300]={};  //We need 277
//int MPPTDataAddress[300] = {};    //We need 277

const int NHKData = 130;
int HKData[NHKData]={};

int temp_HeatSink;
int temp_RTS;
int temp_BAT;
double scalingV;
double scalingA;
double BatteryV = 0;
double BatteryVInput=0;
double ChargingI = 0;

///=========Needed to be defined==========////
const unsigned long PCOffDelayMin = 30;  //s; always give time for PC shutdown

const int NNameCode = 5;
const int CodeBootup = 0;
const int CodeOverLow = 1;
const int CodeLostPC = 2;
const int CodeLostMPPT = 3;
const int CodeShutdown = 4;

float VLevel[NNameCode]={0};
float BootupV_ = 52.8;  //26.4; //for 24V //13.2;  //for 12V //Important: decide when PC is going to power on
float ShutdownV_ = 46.0;  //23.0 for 24V;  //11.5;  //12V //HK data: warning 0->1 if V<ShutdownV; PC take care the counter
float OverLowV_ = 40.0;//20.0; //11.0;  //must lower than ShutdownV; for secure MPPT controller; shut down PC and all relays


const int cnt2min = 60; //
int Alarm_ReadBsicPCOff=1*cnt2min;  //Perido of updating the data when the PC is off
int Count_ReadBsicPCOff=0;
int BootupAlarm_ = 3;  //min
int OverLowAlarm_ = 3;  //min
int LostPCAlarm_ = 60;  //min

int Alarm[NNameCode]={0};
int Count[NNameCode]={0}; //0: Bootup; 2: OverLow; 5: LostPC



bool Warning[NNameCode]={0};  //0: bootup; 1: shutdown; 2: OverLow; 3: LostMPPT

unsigned long  SleepTime = 0;   // *1.0s

int CommandLength = 0;
int MPPTFailCount = 0;
int len = 8;
int tmp=0;

char Char_0 = '0';
char Char_1 = '1';

void setup()
{
  Serial.begin(9600); //to PC; pin 0 (Rx) & 1 (Tx)  for TTL serial data
  VLevel_Setup();
  Alarm_Setup();
  Alarm_ResetWarning();
  Alarm_ResetCount();

  Relay_Setup();

  MPPT_Setup();
  FBB_Setup();  //Forced-Bootup Button
  DHT_Setup();  //DHT22 temperature and humidity sensor

  Fan_Setup();

  delay(50);
  
}

void Fan_Setup(){
  pinMode(Pin_PWMFan1, OUTPUT);   // sets the pin as output
  pinMode(Pin_PWMFan2, OUTPUT);   // sets the pin as output
  // Fan_pwm25kHzBegin();
  FanMode=1;
  Fan_SetDutyCycle(Fan_DutyCycle[FanMode]);  // To initialize the duty cycle of fan1
}

void Fan_SetMode(float T){
    for(short m=0; m< NFanMode; m++){
    if(T<= Fan_TempLvUpper[m]){
      if( m != FanMode ){
        FanMode = m;
        Fan_SetDutyCycle(Fan_DutyCycle[ FanMode ]);
      }
      break;      
    }
  }
}
void Fan_SetDutyCycle(double _dutyCycle){
  int _cycle = (int) (_dutyCycle/100.*256);
  if (_cycle == 256) _cycle=255;
  analogWrite(Pin_PWMFan1, _cycle );
  analogWrite(Pin_PWMFan2, _cycle );
}

void Fan_Print(){
  for(short m=0; m< NFanMode; m++){
    Serial.print(Fan_TempLvUpper[m]);Serial.print("\t"); 
  }
  for(short m=0; m< NFanMode; m++){
    Serial.print(Fan_DutyCycle[m]);Serial.print("\t"); 
  }  
}
void Fan_Println(){
  for(short m=0; m< NFanMode; m++){
    Serial.print(Fan_TempLvUpper[m]);Serial.print("\t"); 
  }
  for(short m=0; m< NFanMode; m++){
    Serial.print(Fan_DutyCycle[m]);Serial.print("\t"); 
  }
  Serial.print("\n"); 
}

void VLevel_Setup(){
  VLevel[CodeBootup] = BootupV_;
  VLevel[CodeShutdown] = ShutdownV_;
  VLevel[CodeOverLow] = OverLowV_;
}
void VLevel_Print(){
  Serial.print(VLevel[CodeBootup]); Serial.print("\t"); 
  Serial.print(VLevel[CodeOverLow]); Serial.print("\t");
  //Serial.print("-");Serial.print("\t");
  //Serial.print("-");Serial.print("\t"); 
  Serial.print(VLevel[CodeShutdown]); Serial.print("\t"); 
  //Serial.print("-");Serial.print("\t");
}
void VLevel_Println(){
  Serial.print(VLevel[CodeBootup]); Serial.print("\t"); 
  Serial.print(VLevel[CodeOverLow]); Serial.print("\t");
  //Serial.print("-");Serial.print("\t");
  //Serial.print("-");Serial.print("\t"); 
  Serial.print(VLevel[CodeShutdown]); Serial.print("\t"); 
  //Serial.print("-");Serial.print("\t");
  Serial.print("\n");
}

void Alarm_ResetWarning(){
  Warning[CodeBootup] = 0;  //bootup
  Warning[CodeShutdown] = 0;  //shutdown
  Warning[CodeOverLow] = 0;  //OverLow
  Warning[CodeLostPC] = 0;  //LostPC
  Warning[CodeLostMPPT] = 0;  //LostNMPPT
}
void Alarm_Setup(){
////default Alarm
  Alarm[CodeBootup] = BootupAlarm_;
  Alarm[CodeOverLow] = OverLowAlarm_;
  Alarm[CodeLostPC] = LostPCAlarm_;
}
void Alarm_Print(){
  Serial.print(Alarm[CodeBootup]);Serial.print("\t");
  Serial.print(Alarm[CodeOverLow]);Serial.print("\t");
  Serial.print(Alarm[CodeLostPC]);Serial.print("\t");  
  //Serial.print("-");Serial.print("\t");
  //Serial.print("-");Serial.print("\t");  
}
void Alarm_Println(){  
  Serial.print(Alarm[CodeBootup]);Serial.print("\t");
  Serial.print(Alarm[CodeOverLow]);Serial.print("\t");
  Serial.print(Alarm[CodeLostPC]);Serial.print("\t");  
  //Serial.print("-");Serial.print("\t");
  //Serial.print("-");Serial.print("\t");  
  Serial.print("\n");    
}
    
void Alarm_ResetCount(){
  Count[CodeBootup] = 0;  //Bootup
  Count[CodeOverLow] = 0;  //OverLow
  Count[CodeLostPC] = 0;  //LostPC
}
void Alarm_UpdateCount(){
  Count[CodeBootup] = (Warning[CodeBootup] == 1)? (Count[CodeBootup] + 1):0;
  Count[CodeOverLow] = (Warning[CodeOverLow] == 1)? (Count[CodeOverLow] + 1):0;
  Count[CodeLostPC] = (Warning[CodeLostPC] == 1)? (Count[CodeLostPC] + 1):0;
}
void Alarm_UpdateWarning(){
  Warning[CodeLostMPPT] = (MPPTFailCount < 3)? 1:0;  
  if (Warning[CodeLostMPPT]==0){  //The value should be read from the MPPT.
    Warning[CodeBootup] = (BatteryV > VLevel[CodeBootup])? 1:0;  //bootup
    Warning[CodeShutdown] = (BatteryV < VLevel[CodeShutdown])? 1:0;  //shutdown
    Warning[CodeOverLow] = (BatteryV < VLevel[CodeOverLow])? 1:0;  //OverLow
  }
  else {
    Warning[CodeBootup] = 0;
    Warning[CodeShutdown] = 0;
    Warning[CodeOverLow] = 0;
  }
  Warning[CodeLostPC] = (CommandLength == 0)? 1:0;
}
void Alarm_Judge(){
  if (Count[CodeBootup] > Alarm[CodeBootup] && relayState[relayNo_PC]==0){
    // Serial.println("High Battery Level: Turn on the PC!");
    Relay_SwitchOnPC(); 
    Alarm_ResetCount();
  }
  else if (Count[CodeOverLow] > Alarm[CodeOverLow] && relayState[relayNo_PC]==1){
    //Serial.println("OverLow Voltage Level! Switch off all!");
    Relay_SwitchOffAll();
    Alarm_ResetCount();        
  }
  else if (Count[CodeLostPC] > Alarm[CodeLostPC] && relayState[relayNo_PC]==1){
    //Serial.println("Lost PC! Switch off all!");
    Relay_SwitchOffAll();
    Alarm_ResetCount();        
  }
}

void FBB_Setup(){
  //Force-Bootup button
  pinMode(Pin_FBB_o, OUTPUT);
  pinMode(Pin_FBB_i, INPUT);
  digitalWrite(Pin_FBB_o, HIGH);   
}
void FBB_Run(){
  if (digitalRead(Pin_FBB_i)==1){  //forced boot-up by pressing button
    Relay_SwitchOnPC();
    Alarm_ResetCount();
  }
}

void MPPT_Setup(){
  // Power on the USB for viewing data in the serial monitor
  Serial1.begin(9600); //communication Rx1  Tx1
  delay(100);
  // Initialize Modbus communication baud rate
  node.begin(9600);

  //see TSMPPT Modbus reference
  int _address, _sum = 0;

//Serial.println("HK address:");
 for(int block=0; block < NMPPTBlock; block++){
    for(int nb=0; nb < NPerMPPTBlock[block]; nb++){
      MPPTDataAddress[ _sum ] =  MPPTBlockStartAddress[ block ] + nb;
      //Serial.print(_sum, DEC); Serial.print("\t");   Serial.println(MPPTDataAddress[ _sum ], HEX);  // print as an ASCII-encoded hexadecimal)
      _sum ++;
    }
 }
/*   
 *    *  //Version #1. record everything from MPPT, but about half of them are not useful: e.g. TCP Network settings, reserved registers for future use
  for (int i = 0; i<278; i++){
    //0 = 0x0000  to 91 = 0x005B
    _address = i;

    if (_address > 91 && _address <= 140){_address = _address + 4004;}  //TCP Network Settings 4096 = 0x1000 to 4144 = 0x1030
    else if (_address > 140 && _address <= 166){_address = _address + 5262;}  //EEPROM; 5403 = 0x151B to 5428 = 0x1534
    else if (_address > 166 && _address <= 200){_address = _address + 57177;} //charge setting; 57344: 0xE000 to 57377: 0xE021
    else if (_address > 200 && _address <= 277){_address = _address + 57271;} //read only section; 0xE080 to 0xE0CD

    MPPTDataAddress[i] = _address;
  }
*/
}

//2017: return bool for communication check
//int MPPT_Available(int _address){
bool MPPT_Available(int _address, int &value){
//  int value=-1;
  value=-1;
  int result = node.readHoldingRegisters(_address, bytesQty);  // result = 1 : error occurred
  if (result != 0) {return false;}
    // If no response from the slave, print an error message
    //Serial.println(result,DEC);
    //Serial.print("\n");
    //Serial.println("MPPTError");
 //2017: comment for prevent timeout
  else {value = node.getResponseBuffer(0);}
  // Clear the response buffer
  node.clearResponseBuffer();
  return true;
}

//convert voltage/current/temperature readings
double MPPT_Scaling(int whole, int fraction)
{return ( whole + fraction/65536 );}

//from scaled value to physical value
double MPPT_RealValue(int value, double scalingV)
{return ( value * scalingV /32768 );}

void HKData_GetBasicHKData(){
  MPPT_ReadBasic();  // Only for collecting the battery voltage and battery charging current.
}
void HKData_GetAllHKData(){
  MPPT_ReadBasic();  // Only for collecting the battery voltage and battery charging current.
  MPPT_ReadAdvanced();  // To collect all of the HK data.
}
void HKData_GetDHTData(){
  DHT_Read();  //temperature and humidity in DAQ box
}
void HKData_Println(){
  Serial.print(Warning[CodeShutdown]);  //HKData_11
  Serial.print(" "); Serial.print(Warning[CodeLostMPPT]);  //HKData_12
  Serial.print(" "); Serial.print(BatteryV);  //HKData_13
  Serial.print(" "); Serial.print(ChargingI);  //HKData_14
  Serial.print(" "); Serial.print(temp_HeatSink);  //HKData_15
  Serial.print(" "); Serial.print(temp_RTS);  //HKData_16
  Serial.print(" "); Serial.print(temp_BAT);  //HKData_17
  Serial.print(" "); 

  //DHT data; 2017 add 
  DHT_Print();  //HKData_18, 19
  Relay_Print();  //HKData_20
  
  //for (int i =0; i<MPPTDataCount; i++){
  for (int i =0; i<NMPPTData; i++){ //HKData_21~130
    Serial.print(MPPTData[i]);Serial.print(" ");
  }
  Serial.println("");
}
void HKData_AddressPrint(){
  //for (int i =0; i<MPPTDataCount; i++){
  for (int i =0; i<NMPPTData; i++){
    Serial.print(MPPTDataAddress[i]); Serial.print(",");
  }
  Serial.println("");
}
////////////////////////////////////////////////////////////////////////Relay
void Relay_Setup(){
  //set relay pins to output for control
  int _relayPin;
  for(int _No =0; _No< NRelay; _No++){
    _relayPin = 22 + _No*2;
    pinMode(_relayPin, OUTPUT);
    pinMode(_relayPin+1, OUTPUT);
    relayState[_No] = 0;//For the reset
    
    /*
    if ( _No==relayNo_SPARE12V || _No==relayNo_SPARE5V || _No==relayNo_SPARE3V3 ){
      Relay_Switch(_No, 1);
    }
    else {
      Relay_Switch(_No, 0);
    }
    //*/
      
    
  }
}
void Relay_Switch(int _No, bool _mode){  // 1 is on.
  //if (relayState[_No] != _mode){  // Running when the state when it need to be changed.
    int _Pin = 22 + _No*2 + _mode;
    digitalWrite(_Pin, HIGH);   
    delay(100);    
    digitalWrite(_Pin, LOW);  
    delay(100);       
    relayState[_No] = _mode;
  //}
}
void Relay_Print(){
  for (int i =1; i< NRelay; i++){  //Skip the state of the PC.
      Serial.print(relayState[i]);
  }
  Serial.print(" ");
}
void Relay_Println(){
  for (int i =1; i< NRelay; i++){  //Skip the state of the PC.
      Serial.print(relayState[i]);
  }
  Serial.print("\n");
}
void Relay_SwitchOffAll(){  //Switching off all the relays.
  for (int iRelay=0; iRelay<NRelay; iRelay++){ 
    Relay_Switch(iRelay, 0); 
  }
}
void Relay_SwitchOnPC(){  //Switching on the PC.
  Relay_Switch(relayNo_PC, 1);
}
void Relay_SwitchOffPC(){  //Switching on the PC.
  Relay_Switch(relayNo_PC, 0);
}


//*
//Bubble sort my ar*e
void isort(int *a, int n){
 for (int i = 1; i < n; ++i) {
   int j = a[i];
   int k;
   for (k = i - 1; (k >= 0) && (j < a[k]); k--)
   {
     a[k + 1] = a[k];
   }
   a[k + 1] = j;
 }
}
//*/
void MPPT_ReadAdvanced(){
  /*
  bool ok=false;
  int failcounter=0;
  Warning[CodeLostMPPT] = 0;  //reset
  //for (int i =0; i<MPPTDataCount; i++){
  for (int i =0; i < NMPPTData; i++){
    if(Warning[CodeLostMPPT]==0){
      ok = MPPT_Available(MPPTDataAddress[i], MPPTData[i]);
      delay(50);
      if(ok==false) failcounter++;
    }
    else{
      //skip all reading if error is found
      MPPTData[i] = -1;
    }
    
    if(failcounter>Alarm[6]){
      Warning[CodeLostMPPT]=1;     //global, used in HKData_Println()
    }
    
  }
  //*/
  //*
  if (Warning[CodeLostMPPT]==0){
    for (int i =0; i < NMPPTData; i++){
      MPPT_Available(MPPTDataAddress[i], MPPTData[i]);
      delay(50);      
    }
  }
  else{
    for (int i =0; i < NMPPTData; i++){
      MPPTData[i] = -1;   
    }    
  }   
  //*/  
}

//const int NBasicHK = 9;
//const int BasicHKAddress[NBasicHK] = { 0, 1, 2, 3, 16, 17, 18, 19, 20};
//{ 0x0000, 0x0001, 0x0002, 0x0003, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027 }; //version 1 with full HK

void MPPT_ReadBasic(){
  /*
  MPPTData[0] = MPPT_Available(0x0000); //Voltage scaling, whole term  V
  MPPTData[1] = MPPT_Available(0x0001); //Voltage scaling, fractional term V
  MPPTData[2] = MPPT_Available(0x0002); //Current scaling, whole term A
  MPPTData[3] = MPPT_Available(0x0003); //Current scaling, fractional term A
  
  MPPTData[16] = MPPT_Available(0x0023); //Heatsink temperature  C
  MPPTData[17] = MPPT_Available(0x0024); //RTS temperature (0x80 = disconnect)  C
  MPPTData[18] = MPPT_Available(0x0025); //Battery regulation temperature  C
  MPPTData[19] = MPPT_Available(0x0026); //Battery voltage, filtered (τ ≈ 1min) V
  MPPTData[20] = MPPT_Available(0x0027); //Charging current, filtered (τ ≈ 1min)  A
  */
  MPPTFailCount = 0;
  MPPTFailCount = MPPTFailCount + MPPT_Available(0x0000, MPPTData[0]); //Voltage scaling, whole term  V
  MPPTFailCount = MPPTFailCount + MPPT_Available(0x0001, MPPTData[1]); //Voltage scaling, fractional term V
  MPPTFailCount = MPPTFailCount + MPPT_Available(0x0026, MPPTData[19]); //Battery voltage, filtered (τ ≈ 1min) V

  MPPT_Available(0x0002, MPPTData[2]);  //Current scaling, whole term A
  MPPT_Available(0x0003, MPPTData[3]);  //Current scaling, fractional term A
  MPPT_Available(0x0027, MPPTData[20]); //Charging current, filtered (τ ≈ 1min)  A

  MPPT_Available(0x0023, MPPTData[16]); //Heatsink temperature  C
  MPPT_Available(0x0024, MPPTData[17]); //RTS temperature (0x80 = disconnect)  C
  MPPT_Available(0x0025, MPPTData[18]); //Battery regulation temperature  C

  
  scalingV = MPPT_Scaling( MPPTData[0],  MPPTData[1] );  //combine whole and fractional terms
  BatteryV = MPPT_RealValue(  MPPTData[19], scalingV);  //scaled value to physical value
  scalingA = MPPT_Scaling( MPPTData[2],  MPPTData[3] );
  ChargingI = MPPT_RealValue( MPPTData[20], scalingA);
  
  temp_HeatSink = MPPTData[16];
  temp_RTS = MPPTData[17];
  temp_BAT = MPPTData[18];
  
  ////TEST
  //BatteryV = BatteryVInput;
  
  
}

void DHT_Setup(){ //DHT22 temperature and humidity sensor  
  DHT1.begin(); 
  DHT2.begin(); 
}
void DHT_Read(){
  float _temp1, _temp2;
  //requesting rate should be less than 0.5 Hz
  _temp1 = DHT1.readTemperature();
  _temp2 = DHT2.readTemperature();
  //humidity = dht.readHumidity();  //0-99.9
  //temp_DHT= dht.readTemperature();//-40 ~ 80
    
  //if fail it returns NaN 
  //According to the IEEE standard, NaN values have the odd property that comparisons involving them 
  //are always false. That is, for a float f, f != f will be true only if f is NaN. 
  DHTData[0] = (_temp1 != _temp1) ? -100 : _temp1;  //for checking healthness
  DHTData[1] = (_temp2 != _temp2) ? -100 : _temp2;
    
  DHT_SetFan();   
}
void DHT_SetFan(){
  Fan_SetMode(  (DHTData[0]+DHTData[0])/2  );
  // Fan_SetMode(  (DHTData[0]+DHTData[1])/2  );
}

void DHT_Print(){ //DHT22 temperature and humidity sensor  
  Serial.print(DHTData[0]); Serial.print(" "); Serial.print(DHTData[1]); Serial.print(" ");
}
void DHT_Println(){ //DHT22 temperature and humidity sensor  
  Serial.print(DHTData[0]); Serial.print(" "); Serial.print(DHTData[1]); Serial.print("\n");
}

int Error_ULStr2Num(char* _ULStr){
  unsigned long _ULNum = strtoul(_ULStr, NULL, 0);
  if ( _ULStr[0]=='-'){return 5;}  //5: Negative
  else if ( _ULNum > 4294967.295){return 6;}  //6: larger than 
  else if ( _ULNum < PCOffDelayMin){return 7;}
  else {return 0;}
}
void Error_Println(int _errorCode){
  if (_errorCode == 0){Serial.println("NO ERROR");}
  else if (_errorCode == 1){Serial.println("ERROR: Wrong $ACTION");}
  else if (_errorCode == 2){Serial.println("ERROR: Wrong $STATEMENT1");}  
  else if (_errorCode == 3){Serial.println("ERROR: Wrong $STATEMENT2");}
  else if (_errorCode == 4){Serial.println("ERROR: Wrong $STATEMENT3");}  
  else if (_errorCode == 5){Serial.println("ERROR: $DELAY/$VALUE is negative");}    
  else if (_errorCode == 6){Serial.println("ERROR: $DELAY/$VALUE is larger than 4294967.295");}
  else if (_errorCode == 7){Serial.print("ERROR: $DELAY is smaller than Min. Delay for shutdown (");Serial.print(PCOffDelayMin);Serial.println(") sec");}
  else {Serial.println("ERROR: UNKOWN");}
}

void loop()
{
  FBB_Run();

  //waiting serial comm from PC
  //Get the number of bytes (characters) available for reading from the serial port. 
  //This is data that's already arrived and stored in the serial receive buffer (which holds 64 bytes)
  CommandLength = Serial.available();
  if (CommandLength!=0){
    
  //*
    char Cmd_PC[128]={0};  //The command from the PC.
    int Len_Cmd_PC=0;
    Count[CodeLostPC] = 0; //reset counter; added in 2017
    Count_ReadBsicPCOff = 0;
    // Serial.print("LostPC Cnt:");           Serial.println(Count[CodeLostPC]);
  
   //Serial.readBytesUntil(character, buffer, length) reads characters from the serial buffer into an array. 
   //The function terminates if the terminator character is detected, the determined length has been read, or it times out 
    Serial.readBytesUntil(' ',Cmd_PC, 64);  // To read the commands in to the char array Cmd_PC.
    Len_Cmd_PC = strlen(Cmd_PC);
    //Serial.println(Cmd_PC);
    // Identification, for making sure that the PC could find Arduino. 
    if (strncmp(Cmd_PC, "?IDN",4)==0){
      Serial.println("Arduino");
    }

    // Asking for HK data.
    else if (strncmp(Cmd_PC, "?HK", 3)==0){  // For collecting and sending the HK data.
      HKData_GetAllHKData();
      HKData_GetDHTData();
      Alarm_UpdateWarning();  // To check whether the battery condition.
      Alarm_UpdateCount();
      HKData_Println();      
    }

    //Asking for the temperature and the humidity.
    else if (strncmp(Cmd_PC, "?DHT", 4)==0){  // For collecting and sending the HK data.
      DHT_Read();
      DHT_Println();   
    }
    //Asking for the states of relays.
    else if (strncmp(Cmd_PC, "?RELAY", 6) ==0){    
      Relay_Println();
      //Relay.Println();
    }
    //To tun on/off the relay.  
    //Format: RELAY XXXXXXXXXXXXXX TIME. The X is 1/0 for in/off. The 1st digit of X is not for the PC.
    //TIME is the time delay in sec (second).
    else if (strncmp(Cmd_PC, "RELAY", 5) ==0 && Len_Cmd_PC==5){ 
      char _Device[30]={0};
      char _State[30]={0};
      Serial.readBytesUntil(' ',_Device, 30); //new relay state
      Serial.readBytesUntil(' ',_State, 30); //new relay state

      int _relayNo=-1;
      if      (strncmp(_Device, "SCOPE1", 6) ==0)   {_relayNo = relayNo_SCOPE1;     }
      else if (strncmp(_Device, "SCOPE2", 6) ==0)   {_relayNo = relayNo_SCOPE2;     }
      else if (strncmp(_Device, "SCOPE3", 6) ==0)   {_relayNo = relayNo_SCOPE3;     }
      else if (strncmp(_Device, "LNA1", 4) ==0)     {_relayNo = relayNo_LNA1;       }
      else if (strncmp(_Device, "LNA2", 4) ==0)     {_relayNo = relayNo_LNA2;       }
      else if (strncmp(_Device, "LNA3", 4) ==0)     {_relayNo = relayNo_LNA3;       }
      else if (strncmp(_Device, "FAN", 3) ==0)      {_relayNo = relayNo_FAN;        }
      else if (strncmp(_Device, "ROUTER", 6) ==0)   {_relayNo = relayNo_ROUTER;        }
      else if (strncmp(_Device, "SPARE12V", 8) ==0) {_relayNo = relayNo_SPARE12V;   }
      else if (strncmp(_Device, "TRGBRD", 6) ==0)   {_relayNo = relayNo_TRGBRD;     }
      else if (strncmp(_Device, "EXTHDD", 6) ==0)      {_relayNo = relayNo_EXTHDD;        }
      else if (strncmp(_Device, "SPARE5V", 7) ==0)  {_relayNo = relayNo_SPARE5V;    }
      else if (strncmp(_Device, "OSC", 3) ==0)      {_relayNo = relayNo_OSC;        }
      else if (strncmp(_Device, "SPARE3V3", 8) ==0){_relayNo = relayNo_SPARE3V3;  }
      else    {Error_Println(2);}
      
      if (strncmp(_State, "0", 1)==0)      {Relay_Switch(_relayNo,0); Relay_Println();}
      else if (strncmp(_State, "1", 1)==0) {Relay_Switch(_relayNo,1); Relay_Println();}
      else {Error_Println(3);}        
      /*
      char _Delay[10]={0}; //1 byte; should be initialized, otherwize cause bug in atoi
      Serial.readBytesUntil(' ',_Delay, 30);  //time delay for next action
      int _errorCode = Error_ULStr2Num(_Delay);
      if (_errorCode==5 || _errorCode==6){Error_Println(_errorCode);} //5: Negative; 6: Larger than 49 days
      else {
        delay( strtoul(_Delay, NULL, 0)*1000 ); //s to ms
        if (strncmp(_State, "0", 1)==0)      {Relay_Switch(_relayNo,0); Relay_Println();}
        else if (strncmp(_State, "1", 1)==0) {Relay_Switch(_relayNo,1); Relay_Println();}
        else {Error_Println(3);}  
      } 
      //*/     
    }    
    else if (strncmp(Cmd_PC, "RELAYS", 6) ==0 && Len_Cmd_PC==6 ){
      char _StateConfig[30]={0};
      char _Delay[10]={0}; //1 byte; should be initialized, otherwize cause bug in atoi
      Serial.readBytesUntil(' ',_StateConfig, 30); //new relay state
      Serial.readBytesUntil(' ',_Delay, 30);  //time delay for next action

      int _errorCode = Error_ULStr2Num(_Delay);
      if (_errorCode==5 || _errorCode==6){Error_Println(_errorCode);} //5: Negative; 6: Larger than 49 days
      else {
        delay( strtoul(_Delay, NULL, 0)*1000 );
        for (int iRelay=1; iRelay<NRelay; iRelay++){  //PC(index 0) relay must be 0 and is skipped
          if (_StateConfig[iRelay-1]==Char_0 || strncmp(_StateConfig, "ALLOFF", 5) ==0 ){Relay_Switch(iRelay, 0);} 
          else if (_StateConfig[iRelay-1]==Char_1 || strncmp(_StateConfig, "ALLON", 6) ==0){Relay_Switch(iRelay, 1);}
          else {Error_Println(3);}
        }       
        Relay_Println();
      }      
    }

    else if  (strncmp(Cmd_PC, "PCRELAYOFF", 10) ==0){
      char _Delay[10]={0}; //1 byte; should be initialized, otherwize cause bug in atoi
      Serial.readBytesUntil(' ',_Delay, 30);  //time delay for next action
      int _errorCode = Error_ULStr2Num(_Delay);
      if (_errorCode==5 || _errorCode == 6 || _errorCode==7){Error_Println(_errorCode);} //5: Negative; 6: Larger than 49 days
      else {
        Serial.print("Shutdown after "); Serial.print(strtoul(_Delay, NULL, 0)); Serial.println(" sec");
        delay(strtoul(_Delay, NULL, 0)*1000);
        Relay_SwitchOffPC(); 
        Alarm_ResetCount();
      }  
    }
    else if  (strncmp(Cmd_PC, "SLEEP", 5) ==0){  //To modify the parameters.
      char _sleepTime[10]={0}; //1 byte; should be initialized, otherwize cause bug in atoi
      Serial.readBytesUntil(' ',_sleepTime, 30);  //time delay for next action
      int _errorCode = Error_ULStr2Num(_sleepTime);
      if (_errorCode==5 || _errorCode==6){Error_Println(_errorCode);} //5: Negative; 6: Larger than 49 days
      else {
        SleepTime = strtoul(_sleepTime, NULL, 0);
        Serial.print("Forced-sleeping for ");  Serial.print(SleepTime); Serial.println(" sec after shutdown.");
      }      
    }       
    else if (strncmp(Cmd_PC, "?ALARM", 6) ==0){
      Alarm_Println();
    }
    else if  (strncmp(Cmd_PC, "ALARM", 5) ==0){  //To modify the parameters.
      char _Name[30]={0};
      char _Value[30]={0};
      Serial.readBytesUntil(' ',_Name,30);
      Serial.readBytesUntil(' ',_Value, 30);      
      int _NameCode;
      if      (strncmp(_Name, "BOOTUP"  ,6) ==0) {_NameCode = CodeBootup;}
      else if (strncmp(_Name, "OVERLOW" ,7) ==0) {_NameCode = CodeOverLow;}
      else if (strncmp(_Name, "LOSTPC"  ,6) ==0) {_NameCode = CodeLostPC;}
      else if (strncmp(_Name, "LOSTMPPT",8) ==0) {_NameCode = CodeLostMPPT;}
      else {Error_Println(2);}

      int _errorCode = Error_ULStr2Num(_Value);
      if (_errorCode==5 || _errorCode==6){Error_Println(_errorCode);} //5: Negative; 6: Larger than 49 days
      else {
        Alarm[_NameCode] = strtoul(_Value, NULL, 0);
        Alarm_Println();
      }        
    }
    else if (strncmp(Cmd_PC, "?VLEVEL", 7) ==0){
      VLevel_Println();
    }   
    else if (strncmp(Cmd_PC, "VLEVEL", 6) ==0 && Len_Cmd_PC==6){  //To modify the parameters.
      char _Name[30]={0};
      char _Value[30]={0};
      Serial.readBytesUntil(' ',_Name,30);
      Serial.readBytesUntil(' ',_Value, 30);
      int _NameCode;
      if      (strncmp(_Name, "BOOTUP"  , 6)==0)    {_NameCode = CodeBootup;}
      else if (strncmp(_Name, "OVERLOW" , 7)==0)    {_NameCode = CodeOverLow;}
      else if (strncmp(_Name, "SHUTDOWN", 8)==0)    {_NameCode = CodeShutdown;}     
      else {Error_Println(2);}

      int _errorCode = Error_ULStr2Num(_Value);
      if (_errorCode==5){Error_Println(_errorCode);} //5: Negative;
      else {
        VLevel[_NameCode] = atof(_Value);
        VLevel_Println();
      }
    }
    //*
    else if (strncmp(Cmd_PC, "?FANPWM", 7) ==0){
      Fan_Println();
    }  
    else if  (strncmp(Cmd_PC, "FANPWM", 6) ==0){  //To modify the parameters.
      char _Name[30]={0};
      char _Value[30]={0};
      int _FanPWMPara; //0: Temp; 1: Duty Cycle 
      int _FanPWMMode; //0: Temp; 1: Duty Cycle 
      Serial.readBytesUntil(' ',_Name,30);
      Serial.readBytesUntil(' ',_Value, 30);      
      int _NameCode;
      if      (strncmp(_Name, "T0" ,2) ==0) {_FanPWMPara=0; _FanPWMMode=0;}
      else if (strncmp(_Name, "T1" ,2) ==0) {_FanPWMPara=0; _FanPWMMode=1;}
      else if (strncmp(_Name, "T2" ,2) ==0) {_FanPWMPara=0; _FanPWMMode=2;}
      else if (strncmp(_Name, "DC0",3) ==0) {_FanPWMPara=1; _FanPWMMode=0;}
      else if (strncmp(_Name, "DC1",3) ==0) {_FanPWMPara=1; _FanPWMMode=1;}
      else if (strncmp(_Name, "DC2",3) ==0) {_FanPWMPara=1; _FanPWMMode=2;}
      else {Error_Println(2);}
    
      if (_FanPWMPara==0){
        float _Temp = atof(_Value);
        float _Fan_TempLvUpper[NFanMode];
        for (int i=0; i<NFanMode; i++){
          _Fan_TempLvUpper[i] = Fan_TempLvUpper[i];
        }
        
        if (_Temp<0||_Temp>1000){Serial.println("Error: The required temperature level is not between [0, 1000].");}
        else {_Fan_TempLvUpper[_FanPWMMode] = _Temp;}
  
        int _MagOrderCheck=0;
        for (int i=0; i<NFanMode-1; i++){
          if (_Fan_TempLvUpper[i]<_Fan_TempLvUpper[i+1]){_MagOrderCheck++;}
        }
        if (_MagOrderCheck==NFanMode-1){
          Fan_TempLvUpper[_FanPWMMode] = _Temp;
          Fan_Println();
        }
        else {Serial.println("Error: The temperature level ordering is wrong. It should be : T0<T1<T2");}
      }
      else if (_FanPWMPara==1){
        byte _DC = strtoul(_Value, NULL, 0);
        if (_DC<0||_DC>79){Serial.println("Error: The duty cycle should be between [0,79]");}
        else {
          Fan_DutyCycle[_FanPWMMode] = _DC;
          Fan_Println();
        }
      }
      else {Error_Println(3);}        
    }
    //*/
    
    // For debugging. To assign a voltage of the battery.
    /* 
    else if (strncmp(Cmd_PC, "BATTV",5)==0){
      char _Value[30]={0}; 
      Serial.readBytesUntil(' ',_Value, 30);            
     // Serial.println("BATTV");
      BatteryVInput = atof(_Value);
    } 
    //*/ 
    
    else {
      Error_Println(1);
    }
  }

  else if (SleepTime > 0 && relayState[relayNo_PC]==0){SleepTime-=1;} //Alarm: Sleep
  //The PC was asking for sleeping.
  else { //No command, sleeping/rebooting alarm is 0 as well.
    // Serial.println(Count_ReadBsicPCOff);
    if (Count_ReadBsicPCOff>=Alarm_ReadBsicPCOff){
      HKData_GetBasicHKData();
      Alarm_UpdateWarning();
      Alarm_UpdateCount();
      Alarm_Judge();
      Count_ReadBsicPCOff=0;  
    }
    else {
      Count_ReadBsicPCOff++;
    }
  }
  
  // DHT_Read();
  // DHT_Println();
  // DHT_SetFan();
  // Fan_Println();
  // Serial.print(FanMode);Serial.print("\t");
  
  /*
  // Serial.println(BatteryV);

  Serial.print("Boot");Serial.print("\t");    
  Serial.print("OverLow");Serial.print("\t");
  Serial.print("NoPC");Serial.print("\t");
  Serial.print("NoMPPT");Serial.print("\t");  
  Serial.print("Shut");Serial.print("\t");
  Serial.print("\n");
  
  Serial.print(Warning[CodeBootup]);Serial.print("\t");  
  Serial.print(Warning[CodeOverLow]);Serial.print("\t");
  Serial.print(Warning[CodeLostPC]);Serial.print("\t");
  Serial.print(Warning[CodeLostMPPT]);Serial.print("\t");    
  Serial.print(Warning[CodeShutdown]);Serial.print("\t");
  Serial.print("\n");

  Serial.print(Count[CodeBootup]);Serial.print("\t");
  Serial.print(Count[CodeOverLow]);Serial.print("\t");
  Serial.print(Count[CodeLostPC]);Serial.print("\t");  
  Serial.print("-");Serial.print("\t"); 
  Serial.print("-");Serial.print("\t");
  Serial.print("\n");  

  Serial.print(Alarm[CodeBootup]);Serial.print("\t");
  Serial.print(Alarm[CodeOverLow]);Serial.print("\t");
  Serial.print(Alarm[CodeLostPC]);Serial.print("\t");  
  Serial.print("-");Serial.print("\t");
  Serial.print("-");Serial.print("\t");  
  Serial.print("\n");

  Relay_Println();  
  Serial.println(Count_ReadBsicPCOff);
  Serial.println("-------------");
  //*/
  delay(1000);  //
  
}

///////////////////////////////////////////
/* 
 *  Ref:
 *   -bit operation
 *   -Secrets of Arduino PWM: http://www.righto.com/2009/07/secrets-of-arduino-pwm.html on Timer/Count register settings
 *   -datasheet of microcontroller on Arduino (Mega 2560: ATMega2560; Mega 1280: ATMega1280
 *    -- Timer <--> multiple pin outputs
 *    
 *    pin mapping for Mega 1280: ATMega1280
 *    Pin Number  Pin Name  Mapped Pin Name
 *   17 PH5 ( OC4C )  Digital pin 8 (PWM)
 *   18  PH6 ( OC2B )  Digital pin 9 (PWM)com3
 *   23 PB4 ( OC2A/PCINT4 ) Digital pin 10 (PWM)
 *    
 *    
 *     list of timers in Arduino Mega 2560:
          timer 0 (controls pin 13, 4);
          timer 1 (controls pin 12, 11);
          timer 2 (controls pin 10, 9);
          timer 3 (controls pin 5, 3, 2);
          timer 4 (controls pin 8, 7, 6);
   *    
 *    
 *   TCCR2A Register:  
 *    Bit 7 6 5 4 3 2 1 0
 *   
(0xB0) COM2A1 COM2A0 COM2B1 COM2B0 – – WGM21 WGM20
Read/Write R/W R/W R/W R/W R R R/W R/W
Initial Value 0 0 0 0 0 0 0 0
 *    
 *     TCCR2B Register: 
 *    Bit 7 6 5 4 3 2 1 0
(0xB1) FOC2A FOC2B – – WGM22 CS22 CS21 CS20 
Read/Write W W R R R/W R/W R/W R/W
Initial Value 0 0 0 0 0 0 0 0
 *    
 *    macro modified from https://forum.arduino.cc/index.php?topic=415167.0 by dlloyd
 */
 /*
void Fan_pwm25kHzBegin() {
  //initialize register, which contains bits of certain lengths: see MCU datasheet
  TCCR2A = 0;                               // Timer/Ccount #2 (TC2) Control Register A
  TCCR2B = 0;                               // TC2 Control Register B
  TIMSK2 = 0;                               // TC2 Interrupt Mask Register
  TIFR2 = 0;                                // TC2 Interrupt Flag Register
  //Waveform Generation Mode (WGM) for Timer #2   3-bit (WGM22, WGM21, WGM20), set to 111 -->  Fast PWM, set TOP at OCR2A ([0,255], instead of default 255), Update of OCRx at BOTTOM=0x00
  //Compare Match Output B Mode for Timer #2 (COM2B): 2-bit (COM2B1, COM2B0), set to 10 --> Clear OC2B on Compare Match, set OC2B at BOTTOM (non-inverting mode)for fast PWM mode
  //Clock Select (CS) for Timer #2, selecting the clock source to be used by the Timer/Counter:   3-bit (CS22, CS21, CS20), set to 010 --> prescaler 8
  TCCR2A |= (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);  // OC2B  (Output Compare 2, B mode) cleared/set on match when up/down counting, fast PWM
  TCCR2B |= (1 << WGM22) | (1 << CS21);     // prescaler 8   -->  16MHz / 8  = 2MHz
  OCR2A = 79;                               // TOP overflow value (Hz):  (16MHz/8) / (79+1)  = 25 kHz
  OCR2B = 0;
}
void Fan_SetDutyCycle(byte ocrb) {
  // OCR2B  = ocrb;
}
//*/
