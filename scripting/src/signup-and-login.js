// Signup and login page module.
module.exports = function($) {
    $('.field.explain + .question-icon').click(function() {
        $(this).prevAll(".field.explain").focus();
    });
}
