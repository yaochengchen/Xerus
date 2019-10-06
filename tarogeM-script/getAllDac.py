#for faster SST config generation

import sys
import os

sys.path.insert(0, '{0}/scripts'.format(os.environ['SNS']) )
from offline import dacs2014 as dac

#2017: mapping for sampling and triggering are swapped
channelstr_to_channelid = {0: 3,
                           1: 2,
                           2: 1,
                           3: 0,
                           4: 7,
                           5: 6,
                           6: 5,
                           7: 4}
#Hpols in trig channel
active_channels = [1, 2, 3]

#channel: sampling 
def getDac(channel, Vth):
	#board_number=205
    #return dac.getDac(205, channelstr_to_channelid[channel], Vth)
    return dac.getDac(205, channel, Vth)


def printAllDac(Vth):
	n_channels = 8
	n_bits = 16

	channels = range(n_channels)
	for ch in channels:  # set trigger thresholds to very low/large values so that no thermal triggering occures
    	#DACS= 0 : 200,4000
		if ch in active_channels:
			print("DACS= {} : {},{}".format( ch, getDac(ch, -Vth), getDac(ch, Vth) ) )
		else:	
			print("DACS= {} : {},{}".format( ch, 200, 2 ** n_bits - 200)  ) 

if __name__ == '__main__':
	if(len(sys.argv)<2):
		print "Usage: python getAllDac.py [magnitude of threshold in mV]"
		sys.exit(1)
	printAllDac( float( sys.argv[1] ) )