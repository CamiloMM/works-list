// Signup and login page module.
module.exports = function($, utils) {
    // When user clicks question icon, focus on the field below it.
    $('.field.explain + .question-icon').click(function() {
        $(this).prevAll(".field.explain").focus();
    });

    // Copy the password from the password field to the confirmation field's pattern.
    // It's wonderful the kinds of things browsers can do now :)
    $('#signup .field[name=password]').keyup(function() {
        var escaped = utils.regExpEscape($(this).val());
        var confirmation = $('.field[name=passwordConfirmation]');
        confirmation.attr('pattern', escaped);

        // We also now need to set the confirmation box's validation status.
        if (escaped === '') {
            var icon = 'asterisk'
        } else {
            if (confirmation.is(':valid')) {
                var icon = 'tick';
            } else {
                var icon = 'cross';
            }
        }
        
        confirmation.siblings('.validation').children('.icon').attr('class', 'icon ' + icon);
    });

    // When email field changes in the signup page, show validity in the icon.
    $('#signup .field[type=email], #signup .field[type=password]').keyup(function() {
        var elem = $(this);
        var value = elem.val();

        if (value === '') {
            var icon = 'asterisk'
        } else {
            if (elem.is(':valid')) {
                var icon = 'tick';
            } else {
                var icon = 'cross';
            }
        }

        elem.siblings('.validation').children('.icon').attr('class', 'icon ' + icon);
    });
}
