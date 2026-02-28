import 'package:flutter_midi_pro/flutter_midi_pro.dart';


void playNote() async {
  final MidiPro midiPro = MidiPro();

  final soundfontId = await midiPro.loadSoundfontAsset(assetPath: "assets/weedsgm3.sf2", bank:0, program: 0);

  await midiPro.selectInstrument(sfId: soundfontId, channel: 0, bank: 0, program: 0);

  midiPro.playNote(sfId: soundfontId, channel: 0, key: 60, velocity: 127);

  midiPro.stopNote(sfId: soundfontId, channel: 0, key: 60);

}