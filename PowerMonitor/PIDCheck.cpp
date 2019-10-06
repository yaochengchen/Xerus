#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h> //getenv
using namespace std;

int main(){
	ifstream inputFile;
	char fname[128];
	sprintf(fname, "%s%s" , getenv("TarogePowCtrlDir"), "/PID.txt" );
	inputFile.open(fname, ios::in);	//"/home/taroge/PowerMonitor/PID.txt"

	int PID[1000000]={};
	int _PID;
	int c=0;
	int i=0;
	bool get=false;
	while (inputFile >> _PID){
		 PID[_PID]++;
	}
	inputFile.close();
//*
	for (int i=0; i<1000000; i++){
		if (PID[i]>2) {
			cout << i << endl;
			get=true;
			break;
		}
	}
	if (!get)cout << 0 << endl;
	//*/
	return 0;
}