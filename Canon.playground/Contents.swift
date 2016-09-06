//Copyright (c) 2016 Devin Roth

import Foundation
import CoreMIDI

//midi setup
var client = MIDIClientRef()
var source = MIDIEndpointRef()

MIDIClientCreate("Canon" as CFString, nil, nil, &client)
MIDISourceCreate(client, "Canon" as CFString, &source)

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

//control variables
var seed = 200
var tempo = 120.0
var time = (tempo/60.0)*1000000.0

let violinIChannel = 144
let violinIIChannel = 145
let violinIIIChannel = 146
let bassoChannel = 147

//number generator
srand48(seed)
func random(_ limit: Int)->Int {
    let limit = Double(limit) - 1
    return Int(round(drand48()*limit))
}

let scale = [2,4,6,7,9,11,1]
let chordProgression = [[2,6,9],[9,1,4],[11,2,6],[6,9,1],[7,11,2],[2,6,9],[7,11,2],[9,13,4]]

var violinI = [0,0,0,0,0,0,0,0]
var violinII = [0,0,0,0,0,0,0,0]
var violinIII = [0,0,0,0,0,0,0,0]
let basso = [50,45,47,42,43,38,43,45]

func melodyFinder(melody: Int, harmony: Int, chord: [Int]) -> Int {
    var newMelody = 0
    let rand = random(2)
    
    if melody < 60 {
        newMelody = melodyUp(melody: melody, chord: chord)
    } else if melody > 80 {
        newMelody = melodyDown(melody: melody, chord: chord)
    } else if rand == 0 {
        newMelody = melodyUp(melody: melody, chord: chord)
    } else if rand == 1 {
        newMelody = melodyDown(melody: melody, chord: chord)
    }
    if newMelody%12 == harmony%12 {
        newMelody = melodyFinder(melody: newMelody, harmony: harmony, chord: chord)
    }
    
    return newMelody
}
func melodyUp(melody: Int, chord: [Int]) -> Int {
    var order = [Int]()
    for note in chord {
        if note <= melody%12 {
            order += [note + 12]
        } else {
            order += [note]
        }
    }
    order.sort()
    return melody + order.first! - melody%12
}
func melodyDown(melody: Int, chord: [Int]) -> Int {
    var order = [Int]()
    for note in chord {
        if note >= melody%12 {
            order += [note - 12]
        } else {
            order += [note]
        }
    }
    order.sort()
    return melody + order.last! - melody%12
}

while true {
    
    //shift violinII to violin III and violinI melody to violinII
//    violinIII = violinII
    violinII = violinI
    
    //generate new melody for violinI
    if violinI.last == 0 {
        violinI[0] = chordProgression[0][random(3)] + 72
    } else {
        violinI[0] = melodyFinder(melody: violinI.last!, harmony: violinI.first!, chord: chordProgression[0])
    }
    for note in 1..<8 {
        violinI[note] = melodyFinder(melody: violinI[note - 1], harmony: violinII[note], chord: chordProgression[note])
    }
    
    //send midi
    for note in 0..<8 {
        
        //notes on
        midiOut(violinIChannel, byte1: violinI[note], byte2: 50)
        midiOut(violinIIChannel, byte1: violinII[note], byte2: 50)
//        midiOut(violinIIIChannel, byte1: violinII[note], byte2: 50)
        midiOut(bassoChannel, byte1: basso[note], byte2: 50)
        
        print(violinI[note])
        
        usleep(useconds_t(time))
        
        //notes off
        midiOut(violinIChannel, byte1: violinI[note], byte2: 0)
        midiOut(violinIIChannel, byte1: violinII[note], byte2: 0)
//        midiOut(violinIIIChannel, byte1: violinII[note], byte2: 0)
        midiOut(bassoChannel, byte1: basso[note], byte2: 0)
    }
}
