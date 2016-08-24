//Copyright (c) 2016 Devin Roth

import Foundation
import CoreMIDI

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
srand48(0)
func random(_ limit: Int)->Int {
    let limit = Double(limit) - 1
    return Int(round(drand48()*limit))
}

//piano notes
var piano:[[Int?]] = [[3,5,-2,-1],
    [9,-1,-2,-1],
    [6,-3,1,1],
    [3,3,-2,1],
    [1,2,1,1],
    [10,-2,-2,-1],
    [7,-1,-2,1],
    [8,nil,-2,-1],
    [nil,nil,4,1],
    [nil,nil,6,-1],
    [nil,nil,nil,5],
    [nil,nil,5,nil],
    [4,nil,1,nil],
    [nil,4,1,nil],
    [nil,4,nil,1],
    [4,-1,3,-1]
]
var pianoNote = 64

//bass notes
var bass = [0,5,10,3,8,1,6,11,4,9,2,7]
var bassNote = 0

//drum rhythms
var ride:[[Bool]] = [
    [false,false,false,true],
    [false,false,true,true],
    [false,true,true,true]
]

//main loop
while true {
    
    //select patterns
    var pianoPattern = random(piano.count)
    var ridePattern = random(ride.count)
    
    //play notes
    for i in 0..<4 {
        
        //piano note on
        if let note = piano[pianoPattern][i]{
            pianoNote = pianoNote + note
            midiOut(144, byte1: pianoNote, byte2: 35 + random(60))
        }
        
        //drums
        if ride[ridePattern][i] == true {
            midiOut(146, byte1: 54, byte2: 20 + random(40)) //ride on
            midiOut(146, byte1: 54, byte2: 0) //ride off
        }
        if i == 1 {
            midiOut(146, byte1: 51, byte2: 20 + random(40)) //hh on
            midiOut(146, byte1: 51, byte2: 0) //hh off
        }
        
        //bass
        if i == 1 {
            midiOut(145, byte1: bass[bassNote]+48, byte2: 0) //bass note off
            
            //reset bass notes
            bassNote += 1
            if bassNote == 12 {
                bassNote = 0
            }
            
            var rand = random(5)
            if rand == 0 {
                midiOut(145, byte1: bass[bassNote]+48-1, byte2: 50) //bass note on
            }
            if rand == 1 {
                midiOut(145, byte1: bass[bassNote]+48+1, byte2: 50) //bass note on
            }
        }
        if i == 3 {
            midiOut(145, byte1: bass[bassNote]+48-1, byte2: 0) //bass note off
            midiOut(145, byte1: bass[bassNote]+48+1, byte2: 0) //bass note off
            midiOut(145, byte1: bass[bassNote]+48, byte2: 50) //bass note on
        }
        
        //set time between notes
        if i == 0 || i == 2 {
            usleep(200000)
        } else {
            usleep(300000)
        }
        
        //piano note off
        midiOut(144, byte1: pianoNote, byte2: 0)
    }
    
    //control the range of piano notes
    if pianoNote > 75 {
        pianoNote -= 12
    } else if pianoNote < 60 {
        pianoNote += 12
    }
}

