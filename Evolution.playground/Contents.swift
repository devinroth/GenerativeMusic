import Foundation
import PlaygroundSupport
import CoreMIDI

// MASTER CONTROLS

// Seed for the random number generator.
var seed = 0

// Tempo. Standard range for tempo is 40-200.
var tempo = 80.0

// Density is the number of notes played in each measure. Each note will be played once before any note will be repeated.
var density = 7

// MIDI SETUP
var client = MIDIClientRef()
var source = MIDIEndpointRef()

MIDIClientCreate("GenerativeMusic" as CFString, nil, nil, &client)
MIDISourceCreate(client, "Evolution" as CFString, &source)

sleep(1)    //wait until midi is set up

// Helper function to send midi notes.
func midiOut(_ status:Int, byte1: Int, byte2:Int) {
    var packet = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
    let packetList = UnsafeMutablePointer<MIDIPacketList>.allocate(capacity: 1)
    let midiDataToSend:[UInt8] = [UInt8(status), UInt8(byte1), UInt8(byte2)];
    packet = MIDIPacketListInit(packetList);
    packet = MIDIPacketListAdd(packetList, 1024, packet, 0, 3, midiDataToSend);
    
    MIDIReceived(source, packetList)
    packet.deinitialize(count: 1)
    packetList.deinitialize(count: 1)
    packetList.deallocate()
}

//number generator
srand48(seed)
func random(_ limit: Int)->Int {
    let limit = Double(limit) - 1
    return Int(round(drand48()*limit))
}

let name = ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]

// Timer is used to call back at the correct temp time to send the midi.
var timer: Timer?

//
/*
    Each mode is a unique set of 7 notes based on the diatonic scale.
    Evolution slowly evolves from lightest to darkest mode in each
    key by changing one note at a time in the following order.
    Lydian->Ionian->Mixolydian->Dorian->Aeolian->Phrygian->Locrian.
    Following the arrival at Locrian the same pattern will continue
    with the bass a half-step lower.
 */

var key = 0
var mode = [0,2,4,6,7,9,11] // starting mode
var alterations = [3,6,2,5,1,4,0] // order of alterations
var ostinato = [0,1,2,3,4,5,6].shuffled()
var melody = random(7)

var beat = 0
var bar = 0
var currentMode = 0


// initial pedal down
midiOut(0b10110000, byte1: 64, byte2: 127) // pedal on

timer = Timer.scheduledTimer(withTimeInterval: 60.0/(tempo*7.0), repeats: true) { _ in
    
    // Put Ostinato in right octave
    var note = mode[ostinato[beat]]
    if note < 0 {
        note = 12 - note
    }
    print(name[note])
    note += 60
    
    
    // Play Ostinato
    midiOut(144, byte1: note, byte2: random(32)+24)
    
    // turn note off after 0.1 seconds
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        midiOut(144, byte1: note, byte2: 0)
    }

    
    // Play Bass Notes
    if bar%28 == 0 && beat == 0 {
        
        let bassNote = key + 36
        
        // turn on new bass notes
        midiOut(145, byte1: bassNote + 12, byte2: random(32)+32)
        
    }
    
    if bar%4 == 0 && beat == 0 {
        // change pedal
        midiOut(0b10110000, byte1: 64, byte2: 0) // pedal off

        // turn pedal on after 0.09 seconds
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            midiOut(0b10110000, byte1: 64, byte2: 127) // pedal on
        }
        
        // Alter notes of mode
        mode[alterations[currentMode]] -= 1
        
        // Notes must be 0-11.
        if mode[alterations[currentMode]] < 0 {
            mode[alterations[currentMode]] = 11
        }
        
        // Change mode
        currentMode += 1
        
        // There are only 7 modes.
        if currentMode == 7 {
            currentMode = 0
            
            // Change Key when we go back to the first mode.
            key -= 1
            
            // Key must be 0-11.
            if key < 0 {
                key == 11
            }
        }
    }
    
    
    // Move to next beat. 0-6
    beat += 1
    if beat == 7 {
        beat = 0
        
        // Move to next bar. 0-3
        bar += 1
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
