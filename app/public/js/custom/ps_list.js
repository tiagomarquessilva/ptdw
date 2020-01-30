$(document).ready(function () {
    let email, health_units_id = [], types_id = [], function_id, current_health_units_id = [], current_types_id = [],
        current_function_id, ps_type;

    $.ajaxSetup({
        headers: {
            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
        }
    });

    // limpa as opções selecionadas do P.S. a editar
    function clear_options() {
        let functions = $('#edit_ps_function > option');
        $('#edit_ps_health_unit > option').each(function () {
            $(this).prop('selected', false);
        });
        $('#edit_ps_type > option').each(function () {
            $(this).prop('selected', false);
        });
        for (let i = 0; i < functions.length; i++) $(functions[i]).prop('selected', false);
    }

    // gera as opções consoante o P.S. a editar
    function generate_ps_options(item_data, id_select) {
        let select_val = [];
        $.each(item_data, function (i, item) {
            $('#' + id_select + ' > option').each(function () {
                if ($(this).val() === item) select_val.push($(this).val());
            });
        });
        if (select_val.length > 0) {
            $('#' + id_select).val(select_val);
            $('#' + id_select).trigger('change');
        }
    }

    // obtém as opções alteradas do form do editar
    function get_current_options(id_select) {
        let current = [];
        $('#' + id_select + ' > option:selected').each(function () {
            current.push($(this).val());
        });
        return current;
    }

    // verifica se houve alterações no form consoante os dados do P.S.
    function check_changes_edit(current_form_id, default_values) {
        let check = true;
        for (let i = 0; i < current_form_id.length; i++) {
            if (current_form_id[i] !== default_values[i]) {
                check = false;
                break;
            }
        }
        return check;
    }

    //ordena o array que vem na base de dados com os valores atuais do form
    function sort_array(array_to_sort, array_sorted) {
        return array_to_sort.sort(function (a, b) {
            return array_sorted.indexOf(a) - array_sorted.indexOf(b);
        });
    }

    function get_id_array(array) {
        var tmp = [];
        for (let i = 0; i < array.length; i++) tmp.push(array[i].id.toString());
        return tmp;
    }

    // quando clica no item da dropdown para editar
    $(document).on('click', '.edit_ps', function () {
        email = $($(this).parents().eq(3)).find('.email_ps').html();

        // chamada AJAX que gera os dados do determinado P.S.
        $.ajax({
            url: window.location.href + '/' + email + '/edit',
            success: function (data) {
                ps_type = data.ps_type;
                health_units_id = get_id_array(data.ps_list[0].unidades_saude);
                types_id = get_id_array(data.ps_list[0].tipos);
                function_id = data.ps_list[0].funcao[0].id;

                clear_options();
                generate_ps_options(health_units_id, "edit_ps_health_unit");
                generate_ps_options(types_id, "edit_ps_type");

                let functions = $('#edit_ps_function > option');
                if (function_id != null) {
                    for (i = 0; i < functions.length; i++) {
                        if (parseInt(functions[i].value) === function_id) {
                            $('#edit_ps_function').val(functions[i].value);
                            $('#edit_ps_function').trigger('change');
                            break;
                        }
                    }
                } else {
                    $('#edit_ps_function').val('default');
                    $('#edit_ps_function').trigger('change');
                }
            },
            error: function (e) {
                alert(e);
            }
        });
    });

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
    $('#add_ps_form').on('submit', function (e) {
        e.preventDefault();

        $.ajax({
            type: "POST",
            dataType: 'json',
            url: window.location.href,
            data: $(this).serialize(),
            success: function (data) {
                if (data.success) window.open(window.location.href, '_self');
                else validation_form(data.insert_errors, data.validate_errors, 'add_ps_form', 'button_add_ps');
            },
            error: function (e) {
                alert(e);
            }
        });
    });

    // quando submete o form para editar P.S.
    $('#edit_ps_form').on('submit', function (e) {
        e.preventDefault();

        current_health_units_id = get_current_options("edit_ps_health_unit", current_health_units_id);
        current_types_id = get_current_options("edit_ps_type", current_types_id);
        current_function_id = $('#edit_ps_function > option:selected').val();
        health_units_id = sort_array(health_units_id, current_health_units_id);
        current_types_id.push(ps_type.toString());
        types_id = sort_array(types_id, current_types_id);

        if (current_function_id === "") current_function_id = null;

        if (current_health_units_id.length > health_units_id.length || current_health_units_id.length < health_units_id.length
            || current_types_id.length > types_id.length || current_types_id.length < types_id.length || current_function_id !==
            function_id.toString() || !check_changes_edit(current_health_units_id, health_units_id) || !check_changes_edit(current_types_id,
                types_id))
            $.ajax({
                type: "PUT",
                dataType: 'json',
                url: window.location.href + '/' + email,
                data: $(this).serialize(),
                success: function (data) {
                    if (data.success) window.open(window.location.href, "_self");
                    else validation_form(data.update_errors, data.validate_errors, 'edit_ps_form', 'button_edit_ps_type_function');
                },
                error: function (e) {
                    alert(e);
                }
            });
    });

    // quando clica no item da dropdown para desativar
    $(document).on('click', '.delete_ps', function () {
        email = $($(this).parents().eq(3)).find('.email_ps').html();

        $("#confirm_del_form").attr("action", window.location.href + '/' + email);
    });
});
