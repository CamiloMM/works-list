
// This function gets called before all else, on DOMContentLoaded.
// It is intended to provide fixes and whatnot.

module.exports = function($, utils) {
    // Trigger change on browser auto-fill after a quarter-second.
    setTimeout(function() {
        $('input').each(function() {
            var elem = $(this);
            if (elem.val()) elem.change();
        })
    }, 250);
}
