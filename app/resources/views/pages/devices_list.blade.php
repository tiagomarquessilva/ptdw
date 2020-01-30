@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            devices_table
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
                <th>Nome</th>
                <th>Data de Registo</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>
                    {{-- dropdown:start --}}
                    @component('components.input_dropdown_secondary')
                        @slot('text')
                            Ações
                        @endslot
                        @slot('dropdown_items')
                            <a class="dropdown-item" data-toggle="modal" data-target="#modal_edit_device">Editar
                                Equipamento</a>
                            <a class="dropdown-item" style="color: red;" href="#">Remover Equipamento</a>
                        @endslot
                    @endcomponent
                    {{-- dropdown:end --}}
                </td>
            </tr>
        @endslot
    @endcomponent
    {{-- table:end --}}
    @include('modals.modal_add_device')
    @include('modals.modal_edit_device')
@endsection
