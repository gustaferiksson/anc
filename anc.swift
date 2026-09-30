import CoreAudio
import Foundation

let modeNames: [UInt32: String] = [1: "off", 2: "anc", 3: "transparency", 4: "adaptive"]
let commands: [String: UInt32] = ["on": 2, "off": 1, "transparency": 3, "adaptive": 4]

var devicesAddress = AudioObjectPropertyAddress(
  mSelector: kAudioHardwarePropertyDevices,
  mScope: kAudioObjectPropertyScopeGlobal,
  mElement: kAudioObjectPropertyElementMain
)
var listeningModeAddress = AudioObjectPropertyAddress(
  mSelector: 0x6c73_746d,
  mScope: kAudioObjectPropertyScopeGlobal,
  mElement: kAudioObjectPropertyElementMain
)
var supportedModesAddress = AudioObjectPropertyAddress(
  mSelector: 0x6c73_6d73,
  mScope: kAudioObjectPropertyScopeGlobal,
  mElement: kAudioObjectPropertyElementMain
)

var devicesSize: UInt32 = 0
AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &devicesSize)
var deviceIDs = [AudioObjectID](repeating: 0, count: Int(devicesSize) / MemoryLayout<AudioObjectID>.size)
AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &devicesSize, &deviceIDs)

guard let device = deviceIDs.first(where: { AudioObjectHasProperty($0, &listeningModeAddress) }) else {
  FileHandle.standardError.write("anc: no connected device with listening modes\n".data(using: .utf8)!)
  exit(1)
}

var current: UInt32 = 0
var modeSize = UInt32(MemoryLayout<UInt32>.size)
AudioObjectGetPropertyData(device, &listeningModeAddress, 0, nil, &modeSize, &current)

var supportedMask: UInt32 = 0
AudioObjectGetPropertyData(device, &supportedModesAddress, 0, nil, &modeSize, &supportedMask)
let supportedCommands = commands.filter { $0.value == 1 || supportedMask & (1 << ($0.value - 2)) != 0 }

let argument = CommandLine.arguments.dropFirst().first
guard let argument else {
  print(modeNames[current] ?? "unknown (\(current))")
  exit(0)
}

if argument == "--list" {
  for (name, mode) in supportedCommands.sorted(by: { $0.value < $1.value }) {
    print(mode == current ? "* \(name)" : "  \(name)")
  }
  exit(0)
}

let requested = argument == "toggle" ? (current == 2 ? 3 : 2) : supportedCommands[argument]
guard var target = requested else {
  let usage = (supportedCommands.keys.sorted() + ["toggle", "--list"]).joined(separator: "|")
  FileHandle.standardError.write("usage: anc [\(usage)]\n".data(using: .utf8)!)
  exit(2)
}

let status = AudioObjectSetPropertyData(device, &listeningModeAddress, 0, nil, modeSize, &target)
guard status == noErr else {
  FileHandle.standardError.write("anc: set failed (\(status))\n".data(using: .utf8)!)
  exit(1)
}
print(modeNames[target] ?? "\(target)")
