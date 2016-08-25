//Copyright (c) 2016 Devin Roth

import Foundation
import CoreMIDI

//master controls
var seed = 1
var tempo = 60

//midi setup
var client = MIDIClientRef()
var source = MIDIEndpointRef()

MIDIClientCreate("GenerativeMusic" as CFString, nil, nil, &client)
MIDISourceCreate(client, "Moonlight" as CFString, &source)

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

//chord generator
func generateChord()->[Int]{
    let root = random(12) + 48
    var third = root + 3 + random(2)
    if third > 60 {
        third = third - 12
    }
    var fifth = root + 7
    if fifth > 60 {
        fifth = fifth - 12
    }
    return [root,third,fifth]
    
}

while true {
    var chord = generateChord()
    var voicing = chord.sorted()
    
    //melody note
    var melody = chord[random(3)] + 24
    var melodyVelocity = 40 + random(20)
    midiOut(144, byte1: melody, byte2: melodyVelocity)
    
    //bass note
    var bass = chord[0] - 12
    var bassVelocity = 20 + random(20)
    midiOut(144, byte1: bass, byte2: bassVelocity)
    
    //pedal
    midiOut(0b10110000, byte1: 64, byte2: 127)
    
    for b in 0..<4 {
        if b == 2 {
            if random(2) == 0 {
                midiOut(144, byte1: melody, byte2: 0)
                melody = chord[random(3)] + 24
                midiOut(144, byte1: melody, byte2: melodyVelocity - 5)
            }
        }
        
        midiOut(144, byte1: voicing[0], byte2: 20 + random(20))
        usleep(useconds_t(20000000/tempo))
        midiOut(144, byte1: voicing[0], byte2: 0)
        midiOut(144, byte1: voicing[1], byte2: 10 + random(20))
        usleep(useconds_t(20000000/tempo))
        
        if b == 3 {
            if random(3) == 0 {
                midiOut(144, byte1: melody, byte2: 0)
                melody = chord[random(3)] + 24
                midiOut(144, byte1: melody, byte2: melodyVelocity - 10)
            }
        }

        midiOut(144, byte1: voicing[1], byte2: 0)
        midiOut(144, byte1: voicing[2], byte2: 10 + random(20))
        usleep(useconds_t(20000000/tempo))
        midiOut(144, byte1: voicing[2], byte2: 0)
    }
    
    midiOut(144, byte1: melody, byte2: 0)
    midiOut(144, byte1: bass, byte2: 0)
    midiOut(0b10110000, byte1: 64, byte2: 0)
    usleep(5000)
}

