@extends('layout.layout')
@section('content')
    <div id="personal_info">
        @component('components.card')
            @slot('title')
                <div class="row">
                    <div class="col-10">
                        Informações Pessoais
                    </div>
                    <div class="col-2 align-self-center text-right">
                        <i class="i-Pen-4" id="button_open_user_info_modal" data-toggle="modal"
                           data-target="#modal_edit_user_info"></i>
                    </div>
                </div>
            @endslot
            @slot('body')
                <div class="ul-contact-detail__info">
                    <div class="row">
                        <div class="col-12 text-center">
                            <div class="ul-contact-detail__info-1">
                                <h5>Nome</h5>
                                <span id="user_name">{{$user_name}}</span>
                            </div>
                        </div>
                        <div class="col-6 text-center">
                            <div class="ul-contact-detail__info-1">
                                <h5>E-mail</h5>
                                <span id="user_email">{{$user_email}}</span>
                            </div>
                        </div>
                        <div class="col-6 text-center">
                            <div class="ul-contact-detail__info-1">
                                <h5>Contacto</h5>
                                <span id="user_contact">{{$user_contact}}</span>
                            </div>
                        </div>
                    </div>
                </div>
            @endslot
        @endcomponent
    </div>
    <div id="notifications">
        {{-- table:start --}}
        @component('components.table')
            @slot('table_id')
                notifications_table
            @endslot
            @slot('title')
                Todos os Alertas
            @endslot
            @slot('aria_describedby')
                Tabela dos alertas
            @endslot
            @slot('buttons')
                {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @endslot
            @slot('search_placeholder')
                Procurar na Tabela...
            @endslot
            @slot('filters')
                {{-- dropdown:start --}}
                @component('components.input_dropdown_secondary')
                    @slot('text')
                        Filtros
                    @endslot
                    @slot('dropdown_items')
                        <div class="dropdown-item">
                            @component('components.input_text_email_num_date')
                                @slot('label')
                                    Exemplo Filtro:
                                @endslot
                                @slot('input_id')
                                    input
                                @endslot
                                @slot('type')
                                    text
                                @endslot
                                @slot('required')
                                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                @endslot
                                @slot('placeholder')
                                    Procurar
                                @endslot
                                @slot('value')
                                @endslot
                            @endcomponent
                        </div>
                    @endslot
                @endcomponent
                {{-- dropdown:end --}}
            @endslot
            @slot('thead')
                <tr>
                    <th>Data</th>
                    <th>Tipo</th>
                    <th>Mensagem</th>
                    <th>Paciente</th>
                    <th>Resolvido</th>
                    <th>Comentário</th>
                    <th></th>
                </tr>
            @endslot
            @slot('tbody')
                @foreach ($notifications as $notification)
                    <tr id="notification_{{$notification->id}}">
                        <td>{{$notification->date}}</td>
                        <td>{{$notification->type}}</td>
                        <td>{{$notification->message}}</td>
                        <td>{{$notification->pacient_name}}</td>
                        @if ($notification->solved)
                            <td><i class="i-Yes text-success"></i></td>
                        @else
                            <td><i class="i-Close text-danger"></i></td>
                        @endif
                        <td>{{$notification->commentary}}</td>
                        @if (!$notification->solved)
                            <td>
                                {{-- button_primary:start --}}
                                @component('components.button_primary')
                                    @slot('type')
                                        button
                                    @endslot
                                    @slot('extra')
                                        data-toggle="modal" data-target="#modal_solve_notification" data-solve
                                    @endslot
                                    @slot('text')
                                        Resolver
                                    @endslot
                                    @slot('button_id')
                                        button_solve_notification
                                    @endslot
                                @endcomponent
                                {{-- button_primary:end --}}
                            </td>
                        @else
                            <td></td>
                        @endif
                    </tr>
                @endforeach
            @endslot
        @endcomponent
        {{-- table:end --}}
    </div>
    @include('modals.modal_solve_notification')
    @include('modals.modal_edit_user_info')
    @push('scripts')
        <script>
            function create_feedback_div(type, div_inner_html) {
                return $("<div></div>").addClass(type + "-input-message").html(div_inner_html);
            }

            function handle_validation_response(modal_id, form, sumbit_button_id, notification_title, notification_body, data) {
                if (data.success) {
                    window.location.replace("{{URL::to('/user_profile')}}");
                } else if (data.insertion_error) {
                    $("#" + sumbit_button_id).after(create_feedback_div("invalid", "Erro! Por favor tentar novamente."));
                } else {
                    $.each(form.find(':input'), function (key, value) {
                        let input_id = value.id;
                        if (data.validation_errors.hasOwnProperty(input_id)) {
                            let invalid_message = "";
                            $.each(data.validation_errors[input_id], function () {
                                invalid_message += "<p>" + this + "</p>";
                            });
                            $("#" + input_id).after(create_feedback_div("invalid", invalid_message));
                            $("#" + input_id).addClass("invalid-input");
                        } else if (input_id != "") {
                            $("#" + input_id).after(create_feedback_div("valid", "Entrada válida"));
                            $("#" + input_id).addClass("valid-input");
                        }
                    });
                }
            }

            $(document).ready(function () {

                // notificações
                let notification_id;

                $('#notifications_table [data-solve]').on('click', function () {
                    let table = $('#notifications_table').DataTable();
                    notification = table.row(this.closest("tr"));
                    notification_id = notification.id().replace('notification_', '');
                });


                let solve_notification_form = $('#solve_notification_form');
                solve_notification_form.on('submit', function (e) {
                    e.preventDefault();
                    $("#solve_notification_form .invalid-input-message").remove();
                    $("#solve_notification_form .valid-input-message").remove();
                    $("#solve_notification_form .invalid-input").removeClass("invalid-input");
                    $("#solve_notification_form .valid-input").removeClass("valid-input");

                    if ($("#solved").val() == "on") {
                        $("#solved").val("1");
                    } else if ($("#solved").val() == "off") {
                        $("#solved").val("0");
                    }

                    $.ajax({
                        url: "{{URL::to('/notifications')}}/" + notification_id,
                        type: 'PUT',
                        dataType: 'json',
                        data: $(this).serialize(),
                        success: function (data) {
                            handle_validation_response("modal_solve_notification", solve_notification_form, "button_solve_notification", "Alerta Resolvido", "O alerta foi resolvido com sucesso!", data);
                        },
                        error: function (e) {
                            alert(e);
                        }
                    });
                });

                // informações pessoais
                $("#button_open_user_info_modal").on('click', function () {
                    $("#edit_user_name").val($("#user_name").html());
                    $("#edit_user_contact").val($("#user_contact").html());
                    $("#edit_user_email").val($("#user_email").html());
                    $("#edit_user_password").val($("#user_password").html());
                });

                let edit_user_info_form = $('#edit_user_info_form');
                edit_user_info_form.on('submit', function (e) {
                    e.preventDefault();
                    $("#edit_user_info_form .invalid-input-message").remove();
                    $("#edit_user_info_form .valid-input-message").remove();
                    $("#edit_user_info_form .invalid-input").removeClass("invalid-input");
                    $("#edit_user_info_form .valid-input").removeClass("valid-input");

                    $.ajax({
                        url: "{{URL::to('/user_profile')}}",
                        type: 'PUT',
                        dataType: 'json',
                        data: $(this).serialize(),
                        success: function (data) {
                            handle_validation_response("modal_edit_user_info", edit_user_info_form, "button_edit_user_info", "Informações Atualizadas!", "Informações atualizadas com sucesso.", data);
                        },
                        error: function (e) {
                            alert(e);
                        }
                    });
                });
            });
        </script>
    @endpush
    @if (session('notifications_updated'))
        @push('scripts')
            <script>
                toastr.success("Alerta resolvido com sucesso.", "Alerta Resolvido!");
            </script>
        @endpush
    @endif
    @if (session('user_updated'))
        @push('scripts')
            <script>
                toastr.success("Informações atualizadas com sucesso.", "Informações Atualizadas!");
            </script>
        @endpush
@endif
@endsection
