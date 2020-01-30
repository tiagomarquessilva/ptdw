@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            health_units_table
        @endslot
        @slot('title')
            Lista de Unidades de Saúde
        @endslot
        @slot('aria_describedby')
            Lista de Unidades de Saúde
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @component('components.button_primary')@slot('type')button @endslot
            @slot('extra')
                data-toggle="modal" data-target="#modal_add_health_unit"
            @endslot
            @slot('text')
                Adicionar Nova Unidade de Saúde
            @endslot
            @slot('button_id')
                button_add_health_unit_modal
            @endslot
            @endcomponent
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
                <th>Nome</th>
                <th>Morada</th>
                <th>Contacto</th>
                <th>E-mail</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            @foreach ($health_units as $health_unit)
                <tr id="{{$health_unit->id}}">
                    <td>{{$health_unit->nome}}</td>
                    <td>{{$health_unit->morada}}</td>
                    <td>{{$health_unit->telefone}}</td>
                    <td>{{$health_unit->email}}</td>
                    <td>
                        {{-- dropdown:start --}}
                        @component('components.input_dropdown_secondary')
                            @slot('text')
                                Ações
                            @endslot
                            @slot('dropdown_items')
                                <a class="dropdown-item" data-edit data-toggle="modal"
                                   data-target="#modal_edit_health_unit">Editar Unidade de
                                    Saúde</a>
                                <a class="dropdown-item" data-toggle="modal" data-delete
                                   data-target="#modal_confirm_del"
                                   style="color: red;">Remover Unidade de Saúde</a>
                            @endslot
                        @endcomponent
                        {{-- dropdown:end --}}
                    </td>
                </tr>
            @endforeach
        @endslot
    @endcomponent
    {{-- table:end --}}
    @include('modals.modal_add_health_unit')
    @include('modals.modal_edit_health_unit')
    @include('modals.modal_confirm_del')

    @push('scripts')
        <script>
            function create_feedback_div(type, div_inner_html) {
                return $("<div></div>").addClass(type + "-input-message").html(div_inner_html);
            }

            function handle_validation_response(modal_id, form, sumbit_button_id, notification_title, notification_body, data) {
                if (data.success) {
                    window.location.replace("{{URL::to('/health_units')}}");
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

                let add_health_unit_form = $('#add_health_unit_form');
                add_health_unit_form.on('submit', function (e) {
                    e.preventDefault();
                    $("#add_health_unit_form .invalid-input-message").remove();
                    $("#add_health_unit_form .valid-input-message").remove();
                    $("#add_health_unit_form .invalid-input").removeClass("invalid-input");
                    $("#add_health_unit_form .valid-input").removeClass("valid-input");
                    $.ajax({
                        url: "{{URL::to('/health_units')}}",
                        type: 'POST',
                        dataType: 'json',
                        data: $(this).serialize(),
                        success: function (data) {
                            handle_validation_response("modal_add_health_unit", add_health_unit_form, "button_add_health_unit", "Unidade de Saúde Inserida", "A unidade de saúde foi inserida com sucesso!", data);
                        },
                        error: function (request, status, error) {
                            console.error(request.responseText);
                        }
                    });
                });

                let health_unit_id;
                $('#health_units_table [data-delete]').on('click', function () {
                    $("#confirm_del_form").attr("action", "{{URL::to('/health_units')}}/" + (this.closest("tr").id));
                });

                $('#health_units_table [data-edit]').on('click', function () {
                    let table = $('#health_units_table').DataTable();
                    let health_unit = table.row(this.closest("tr"));
                    let health_unit_data = health_unit.data();
                    $("#edit_health_unit_name").val(health_unit_data[0]);
                    $("#edit_health_unit_address").val(health_unit_data[1]);
                    $("#edit_health_unit_contact").val(health_unit_data[2]);
                    $("#edit_health_unit_email").val(health_unit_data[3]);
                    health_unit_id = health_unit.id();
                });

                let edit_health_unit_form = $('#edit_health_unit_form');
                edit_health_unit_form.on('submit', function (e) {
                    e.preventDefault();
                    $("#edit_health_unit_form .invalid-input-message").remove();
                    $("#edit_health_unit_form .valid-input-message").remove();
                    $("#edit_health_unit_form .invalid-input").removeClass("invalid-input");
                    $("#edit_health_unit_form .valid-input").removeClass("valid-input");
                    $.ajax({
                        url: "{{URL::to('/health_units')}}/" + health_unit_id,
                        type: 'POST',
                        dataType: 'json',
                        data: $(this).serialize(),
                        success: function (data) {
                            handle_validation_response("modal_edit_health_unit", edit_health_unit_form, "button_edit_health_unit", "Unidade de Saúde Editada", "A unidade de saúde foi editada com sucesso!", data);
                        },
                        error: function (e) {
                            console.error(e);
                        }
                    });
                });
            });
        </script>
    @endpush
    @if (session('health_unit_inserted'))
        @push('scripts')
            <script>
                toastr.success("Unidade de saúde inserida com sucesso.", "Unidade de Saúde Inserida!");
            </script>
        @endpush
    @endif
    @if (session('health_unit_updated'))
        @push('scripts')
            <script>
                toastr.success("Unidade de saúde editada com sucesso.", "Unidade de Saúde Editada!");
            </script>
        @endpush
    @endif
    @if (session('health_unit_deleted'))
        @push('scripts')
            <script>
                if ("{{session('health_unit_deleted')}}") {
                    toastr.success("Unidade de saúde eliminada com sucesso.", "Unidade de Saúde Eliminada!");
                } else {
                    toastr.error("Unidade de saúde não eliminada.", "Unidade de Saúde Não Eliminada!");
                }
            </script>
        @endpush
    @endif
@endsection
