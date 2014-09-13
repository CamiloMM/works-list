
// Various utilities.

// Escape a string to use it in a regular expression.
// Taken from Google's code at:
// http://closure-library.googlecode.com/git-history/docs/local_closure_goog_string_string.js.source.html#line1021
exports.regExpEscape = function(s) {
    // I'm blissfully unaware of why the fuck they're replacing \x08 in particular.
    // Probably some corner case related to old Internet Explorer, but meh, I'll leave it.
    return String(s).replace(/([-()\[\]{}+?*.$\^|,:#<!\\])/g, '\\$1').replace(/\x08/g, '\\x08');
};
