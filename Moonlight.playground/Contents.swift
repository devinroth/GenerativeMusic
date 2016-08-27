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

sleep(1)    //wait until midi is set up

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
    let root = random(12)
    let third = root + 3 + random(2)
    let fifth = root + 7

    return [root,third,fifth]
    
}
//melody generator
func generateMelody(_ chord: [Int]) -> Int {
    var melody = chord[random(3)] + 72
    if melody > 84 {
        melody -= 12
    }
    return melody
}
//voice chord
func createVoicing(_ chord: [Int]) -> [Int] {
    var voicing = chord
    for note in 0..<voicing.count {
        voicing[note] += 48
        if voicing[note] > 60 {
            voicing[note] -= 12
        }
    }
    return voicing.sorted()
}

while true {
    var chord = generateChord()
    var voicing = createVoicing(chord)
    
    //melody note
    var melody = generateMelody(chord)
    var melodyVelocity = 40 + random(20)
    midiOut(144, byte1: melody, byte2: melodyVelocity) // melody note on
    
    //bass note
    var bass = chord[0] + 36
    var bassVelocity = 20 + random(20)
    midiOut(144, byte1: bass, byte2: bassVelocity) // bass note on
    
    for beat in 1...4 {
        
        if beat == 3 {
            if random(2) == 0 {
                midiOut(144, byte1: melody, byte2: 0) // melody note off
                var melody = generateMelody(chord)
                midiOut(144, byte1: melody, byte2: melodyVelocity - 5) // melody note on
            }
        }
        
        for triplet in 1...3 {
            
            if beat == 4 && triplet == 3 {
                if random(3) == 0 {
                    midiOut(144, byte1: melody, byte2: 0) // melody note off
                    var melody = generateMelody(chord)
                    midiOut(144, byte1: melody, byte2: melodyVelocity - 10) // melody note on
                }
            }
            
            midiOut(144, byte1: voicing[triplet - 1], byte2: 20 + random(20)) // voicing note on
            
            usleep(useconds_t(20000000/tempo))
            
            midiOut(0b10110000, byte1: 64, byte2: 127) // pedal on
            midiOut(144, byte1: voicing[triplet - 1], byte2: 0) // voicing note off
        }
    }
    
    midiOut(144, byte1: melody, byte2: 0)
    midiOut(144, byte1: bass, byte2: 0)
    midiOut(0b10110000, byte1: 64, byte2: 0) // pedal off
}

