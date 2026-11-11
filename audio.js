(function () {
  "use strict";

  var context = null;
  var unavailable = false;
  var masterVolume = 1;
  var muted = false;

  function getContext() {
    if (context || unavailable) return context;

    try {
      var AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (!AudioContextClass) {
        unavailable = true;
        return null;
      }

      context = new AudioContextClass();
    } catch (error) {
      unavailable = true;
      return null;
    }

    return context;
  }

  function play(makeSound) {
    try {
      if (muted) return;

      var audio = getContext();
      if (!audio) return;

      if (audio.state === "suspended" && typeof audio.resume === "function") {
        var resumeResult = audio.resume();
        if (resumeResult && typeof resumeResult.catch === "function") {
          resumeResult.catch(function () {});
        }
      }

      var masterGain = audio.createGain();
      masterGain.gain.setValueAtTime(masterVolume, audio.currentTime);
      masterGain.connect(audio.destination);

      makeSound(audio, masterGain);
    } catch (error) {
      // Audio is optional; playback failures must not interrupt gameplay.
    }
  }

  function tone(audio, masterGain, shape, startFrequency, endFrequency, duration, volume, delay) {
    var oscillator = audio.createOscillator();
    var gain = audio.createGain();
    var start = audio.currentTime + (delay || 0);
    var end = start + duration;

    oscillator.type = shape;
    oscillator.frequency.setValueAtTime(startFrequency, start);
    oscillator.frequency.exponentialRampToValueAtTime(endFrequency, end);

    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(volume, start + 0.008);
    gain.gain.exponentialRampToValueAtTime(0.0001, end);

    oscillator.connect(gain);
    gain.connect(masterGain);
    oscillator.start(start);
    oscillator.stop(end + 0.01);
  }

  window.Bunker07Audio = {
    setMasterVolume: function (volume) {
      if (typeof volume === "number" && isFinite(volume)) {
        masterVolume = Math.max(0, Math.min(1, volume));
      }
      return masterVolume;
    },

    getMasterVolume: function () {
      return masterVolume;
    },

    setMuted: function (value) {
      muted = Boolean(value);
      return muted;
    },

    getMuted: function () {
      return muted;
    },

    fire: function () {
      play(function (audio, masterGain) {
        tone(audio, masterGain, "sawtooth", 720, 155, 0.12, 0.16);
      });
    },

    hit: function () {
      play(function (audio, masterGain) {
        tone(audio, masterGain, "triangle", 190, 48, 0.18, 0.28);
      });
    },

    reload: function () {
      play(function (audio, masterGain) {
        tone(audio, masterGain, "square", 880, 520, 0.045, 0.08);
        tone(audio, masterGain, "square", 620, 310, 0.07, 0.07, 0.09);
      });
    }
  };
})();
