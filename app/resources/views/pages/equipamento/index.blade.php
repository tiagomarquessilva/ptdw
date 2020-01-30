@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            tabela_equipamentos
        @endslot
        @slot('title')
            Lista de Equipamentos
        @endslot
        @slot('aria_describedby')
            Lista de Equipamentos
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @component('components.button_primary')@slot('type')button @endslot
            @slot('extra')
                data-toggle="modal" data-target="#modal_add_device"
            @endslot
            @slot('text')
                Adicionar Novo Equipamento
            @endslot
            @slot('button_id')
                button_add_device_modal
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
                <th>ID</th>
                <th>Nome</th>
                <th>Token</th>
                <th>Tem Paciente Associado</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            @foreach ($equipamentos as $equipamento)
                <tr>
                    <td> {{$equipamento->id}}</td>
                    <td> {{$equipamento->nome}}</td>
                    <td> {{$equipamento->access_token}}</td> 
                    @if ($equipamento->esta_associado() == "sim")
                        <td><i class="i-Yes text-success"></i></td>
                    @else
                        <td><i class="i-Close text-danger"></i></td>
                    @endif
                    <td>
                        {{-- dropdown:start --}}
                        @component('components.input_dropdown_secondary')
                            @slot('text')
                                Ações
                            @endslot
                            @slot('dropdown_items')
                                <a class="dropdown-item" data-edit data-toggle="modal" data-target="#modal_edit_device">Editar
                                    Equipamento</a>
                                @if($equipamento->esta_associado() == "sim")
                                    <a class="dropdown-item text-success "
                                       href="{{URL::to('/calibracao/'.$equipamento->id)}}">Calibrar Equipamento</a>
                                @endif
                                <a class="dropdown-item" data-remove style="color: red;" href="#">Remover
                                    Equipamento</a>
                            @endslot
                        @endcomponent
                        {{-- dropdown:end --}}
                    </td>
                </tr>
            @endforeach
        @endslot
    @endcomponent

    {{-- table:end --}}
    @include('modals.modal_add_device')
    @include('modals.modal_edit_device')


    @push("scripts")
        <script>

            var tabela;
            var device;
            $(document).ready(function () {
                table = $('#tabela_equipamentos').DataTable();
                table.column(0).visible(false);
                table.columns.adjust().draw(false); // adjust column sizing and redraw

                // colcar informações na modal de editar
                $('#tabela_equipamentos [data-edit]').on('click', function () {
                    device = table.row(this.closest("tr"));
                    let device_data = device.data();
                    $("#id").val(device_data[0]);
                    $("#nome_edit").val(device_data[1]);
                    $("#token").val(device_data[2]);
                });

                //Eleminar equipamento
                $('#tabela_equipamentos [data-remove]').on('click', function () {
                    device = table.row(this.closest("tr"));
                    let device_data = device.data();
                    let device_id = device_data[0];

                    $.ajax({
                        type: "POST",
                        url: "{{URL::to('/equipamento')}}" + "/" + device_id,
                        dataType: 'json',
                        data: {
                            id: device_id,
                            _method: 'DELETE'
                        },
                        headers: {
                            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                        },
                        success: function (data) {
                            // refresh page
                            //var url = "{{URL::to('/')}}" + data.redirect;
                            //$(location).attr('href', url);


                            table.row(device.index()).remove();
                            table.draw();

                        }
                    });

                });
            });

            //associate
            $('#not_associate').on('click', function () {
                if($(this).is(':checked')){
                    $("#associate_patient_div").hide();
                } else {
                    $("#associate_patient_div").show();
                }
            });
        </script>
    @endpush


@endsection
