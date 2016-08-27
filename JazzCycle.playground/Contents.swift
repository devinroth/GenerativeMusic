//Copyright (c) 2016 Devin Roth

import Foundation
import CoreMIDI

//control variables
var seed = 1
var tempo = 120


//midi setup
var client = MIDIClientRef()
var source = MIDIEndpointRef()

MIDIClientCreate("Jazz" as CFString, nil, nil, &client)
MIDISourceCreate(client, "Jazz Out" as CFString, &source)

sleep(1)    //wait until midi is setup

func midiOut(_ status:Int, byte1: Int, byte2:Int) {
    var packet = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
    let packetList = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
    let midiDataToSend:[UInt8] = [UInt8(status), UInt8(byte1), UInt8(byte2)];
    packet = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, 1024, packet, 0, 3, midiDataToSend);
    
    MIDIReceived(source, packetList)
    packet.deinitialize()
    packetList.deinitialize()
    packetList.deallocate(capacity: 1)
}

//number generator
srand48(seed)
func random(_ limit: Int)->Int {
    let limit = Double(limit) - 1
    return Int(round(drand48()*limit))
}

//piano notes
var piano:[[Int?]] = [
    [nil,    nil,   nil,    nil,    nil,    nil ],
    [nil,    nil,   nil,    nil,    5,      nil ],
    [nil,    nil,   nil,    nil,    6,      -1  ],
    [nil,    4,     nil,    nil,    1,      nil ],
    [nil,    nil,   nil,    nil,    4,      1   ],
    [nil,    nil,   4,      nil,    1,      nil ],
    [nil,    nil,   4,      nil,    nil,    1   ],
    [nil,    8,     nil,    nil,    -2,     -1  ],
    [nil,    3,     5,      nil,    -2,     -1  ],
    [nil,    9,     -1,     nil,    -2,     -1  ],
    [nil,    6,     -3,     nil,    1,      1   ],
    [nil,    3,     3,      nil,    -2,     1   ],
    [nil,    1,     2,      nil,    1,      1   ],
    [nil,    10,    -2,     nil,    -2,     -1  ],
    [nil,    7,     -1,     nil,    -2,     1   ],
    [nil,    4,     -1,     nil,    3,      -1  ],
    [nil,    3,     nil,    3,      -2,     1   ],
    [1,     1,     1,       nil,    3,     -1   ],
    [1,     1,     1,       3,      -2,     1   ],
    
]
var pianoNote = 64

var pianoChords = [[4,10,14],[-2,4,9]]

//bass notes
var bass = [0,5,-2,3,-4,1,6,-1,4,-3,2,-5]
var bassNote = 0

//drum rhythms
var ride:[[Bool]] = [
    [false,false,false,false,false,true],
    [false,false,false,false,true,true],
    [false,false,true,false,true,true]
]

var chord = pianoChords[bassNote%2]

//main loop
while true {
    
    //select patterns
    var pianoPattern = random(piano.count)
    if pianoPattern == 0 {
        pianoNote += 5
    }
    var ridePattern = random(ride.count)
    
    
    //play notes
    for i in 0..<6 {
        
        //piano solo note on
        if let note = piano[pianoPattern][i]{
            midiOut(144, byte1: pianoNote + 12, byte2: 0)
            midiOut(144, byte1: pianoNote - 12, byte2: 0)
            midiOut(144, byte1: pianoNote, byte2: 0)
            pianoNote = pianoNote + note
            print(pianoNote)
            midiOut(144, byte1: pianoNote, byte2: 35 + random(60))
        }
        
        // piano chords
        if i == 1 && random(4) == 0 {
            //piano chords off
            for note in chord {
                midiOut(144, byte1: note + bass[bassNote] + 48, byte2: 0)
            }
            var chordVelocity = 30 + random(50)
            for note in chord {
                midiOut(144, byte1: note + bass[bassNote] + 48, byte2: chordVelocity )
            }
        }
        if i == 4 {
            if bassNote < 6 {
                chord = pianoChords[bassNote%2]
            } else {
                chord = pianoChords[1 - bassNote%2]
            }
            var chordVelocity = 20 + random(50)
            for note in chord {
                midiOut(144, byte1: note + bass[bassNote] + 48, byte2: chordVelocity)
            }
        }
        
        //drums
        if ride[ridePattern][i] == true {
            midiOut(146, byte1: 54, byte2: 20 + random(40)) //ride on
            midiOut(146, byte1: 54, byte2: 0) //ride off
        }
        if i == 2 {
            midiOut(146, byte1: 52, byte2: 30 + random(40)) //hh on
            midiOut(146, byte1: 52, byte2: 0) //hh off
        }
        
        //bass
        if i == 2 {
            midiOut(145, byte1: bass[bassNote]+48, byte2: 0) //bass note off
            
            //reset bass notes
            bassNote += 1
            if bassNote == 12 {
                bassNote = 0
            }
            
            var rand = random(3)
            if rand == 0 {
                midiOut(145, byte1: bass[bassNote]+48-1, byte2: 50) //bass note on
            }
            if rand == 1 {
                midiOut(145, byte1: bass[bassNote]+48+1, byte2: 50) //bass note on
            }
        }
        if i == 4 {
            var rand = random(4)
            if rand == 0 {
                midiOut(145, byte1: bass[bassNote]+48-1, byte2: 50) //bass note on
            }
            if rand == 1 {
                midiOut(145, byte1: bass[bassNote]+48+1, byte2: 50) //bass note on
            }
        }
        if i == 5 {
            midiOut(145, byte1: bass[bassNote]+48-1, byte2: 0) //bass note off
            midiOut(145, byte1: bass[bassNote]+48+1, byte2: 0) //bass note off
            midiOut(145, byte1: bass[bassNote]+48, byte2: 50) //bass note on
        }
        
        //set time between notes
        if i == 2 || i == 5 {
           usleep(useconds_t((60_000_000*1)/(tempo*3)))
        }
        if i == 0 || i == 3 {
            usleep(useconds_t((60_000_000*4)/(tempo*15)))
        }
        if i == 1 || i == 4 {
            usleep(useconds_t((60_000_000*2)/(tempo*5)))
        }
        
        //piano chords off
        for note in chord {
            midiOut(144, byte1: note + bass[bassNote] + 48, byte2: 0)
        }
    }
    
    //control the range of piano notes
    if pianoNote > 90 {
        pianoNote -= 12
    } else if pianoNote < 60 {
        pianoNote += 12
    } else {
        pianoNote = pianoNote - 12 * random(2)
    }
}

