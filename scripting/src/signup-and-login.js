var _ = require('lodash');

// Signup and login page module.
module.exports = function($, utils) {
    // Internal validation cache.
    var cache = {names: {}};

    // Name-checking function that queries the server to see if a name is valid.
    // This function is cached and rate-limited.
    var checkName = _.debounce(function(name, callback) {
        if (cache.names[name]) {
            callback(cache.names[name]);
        } else {
            $.post('/api/validate/user', {name: name}, function(data) {
                if (!_.isObject(data)) data = {reason: 'Server error.'};
                callback(cache.names[name] = data);
            });
        }
    }, 500);

    // When user clicks question icon, focus on the field below it.
    $('.field.explain + .question-icon').click(function() {
        $(this).prevAll(".field.explain").focus();
    });

    // Copy the password from the password field to the confirmation field's pattern.
    // It's wonderful the kinds of things browsers can do now :)
    $('#signup .field[name=password]').on('keyup change', function() {
        var escaped = utils.regExpEscape($(this).val());
        var confirmation = $('.field[name=passwordConfirmation]');
        confirmation.attr('pattern', escaped);

        // We also now need to set the confirmation box's validation status.
        if (escaped === '') {
            var icon = 'asterisk'
        } else {
            var icon = confirmation.is(':valid') ? 'tick' : 'cross';
        }

        confirmation.siblings('.validation').children('.icon').attr('class', 'icon ' + icon);
    });

    // When email field changes in the signup page, show validity in the icon.
    $('#signup .field[type=email], #signup .field[type=password]').on('keyup change', function() {
        var elem = $(this);

        if (elem.val() === '') {
            var icon = 'asterisk'
        } else {
            var icon = elem.is(':valid') ? 'tick' : 'cross';
        }

        elem.siblings('.validation').children('.icon').attr('class', 'icon ' + icon);
    });

    // Verify name availability on signup.
    $('#signup .field[name=username]').on('keyup change', function() {
        var elem = $(this);
        var value = elem.val();

        if (value === '') {
            var icon = 'asterisk';
        } else {
            if (elem.is(':valid')) {
                // If the cache contains an answer, use that.
                if (cache.names[value]) {
                    var icon = cache.names[value].valid ? 'tick' : 'cross';
                } else {
                    // We'll have to check the database.
                    var icon = 'loading';
                }
            } else {
                var icon = 'cross';
            }
        }

        // If the field is blank, we'll leave an asterisk.
        // If it's invalid, we'll leave a cross.
        // If it's valid, we'll leave a loading icon, and check on the server after.
        var validationIcon = elem.siblings('.validation').children('.icon');
        validationIcon.attr('class', 'icon ' + icon);

        // Now, if the the field wasn't blank, was valid, and not cached, we should check it.
        if (icon === 'loading') {
            // The name is only checked after half a second since the user stopped typing.
            checkName(value, function(data) {
                // Only change anything if the value hasn't been changed since last time.
                if (elem.val() === value) {
                    icon = data.valid ? 'tick' : 'cross';
                    validationIcon.attr('class', 'icon ' + icon);
                }
            });
        }
    });
}
