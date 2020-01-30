$(document).ready(function () {
    function validation_add_div(type_validation, msg) {
        return $('<div></div>').addClass(type_validation + '-input-message').html(msg);
    }

    function validation_form(exception_errors, validate_errors, form_id, form_button_id) {
        $('#' + form_button_id + ' + div').remove();

        if (exception_errors) $('#' + form_button_id).after(validation_add_div('invalid', '<p>Erro! Por favor tente novamente.</p>'));
        else {
            $.each($('#' + form_id + ' :input'), function (i, item) {
                let input_id = item.id;

                if (input_id !== '') $('#' + input_id + ' + div').remove();

                if (validate_errors.hasOwnProperty(input_id)) {
                    $("#" + input_id).after(validation_add_div('invalid', '<p>' + validate_errors[input_id] + '</p>'));
                    $("#" + input_id).addClass("invalid-input");
                } else if (input_id !== '') {
                    $("#" + input_id).after(validation_add_div('valid', 'Entrada válida'));
                    $("#" + input_id).addClass("valid-input");
                }
            });
        }

    }

    // quando submete o form para adicionar P.S.
    $('#add_caretaker').on('submit', function (e) {
        e.preventDefault();

        $.ajax({
            type: "POST",
            dataType: 'json',
            url: window.location.href,
            data: $(this).serialize(),
            success: function (data) {
                if (data.success) window.open(window.location.href, '_self');
                else validation_form(data.insert_errors, data.validate_errors, 'add_caretaker', 'button_add_caretaker');
            },
            error: function (e) {
                alert(e);
            }
        });
    });
});
