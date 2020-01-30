@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            patients_table
        @endslot
        @slot('title')
            Lista de Pacientes
        @endslot
        @slot('aria_describedby')
            Lista de pacientes
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @component('components.button_primary')@slot('type')button @endslot
            @slot('extra')
                data-toggle="modal" data-target="#modal_add_patient"
            @endslot
            @slot('text')
                Adicionar Novo Paciente
            @endslot
            @slot('button_id')
                button_add_patient_modal
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
                <th>Género</th>
                <th>Doença</th>
                <th>Data de nascimento</th>
                <th>Data de diagnóstico</th>
                <th>Músculo onde colocar o sensor</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>
                    {{-- dropdown:start --}}
                    @component('components.input_dropdown_secondary')
                        @slot('text')
                            Ações
                        @endslot
                        @slot('dropdown_items')
                            <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_info">Ver
                                Informações do Paciente</a>
                            <a class="dropdown-item" href="#">Ver Histórico do Paciente</a>
                            <a class="dropdown-item" href="#">Calibrar Paciente</a>
                            <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_help_request">Enviar
                                pedido de
                                ajuda</a>
                            <a class="dropdown-item" style="color: red;" href="#">Remover Paciente</a>
                        @endslot
                    @endcomponent
                    {{-- dropdown:end --}}
                </td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>
                    {{-- dropdown:start --}}
                    @component('components.input_dropdown_secondary')
                        @slot('text')
                            Ações
                        @endslot
                        @slot('dropdown_items')
                            <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_info">Ver
                                Informações do Paciente</a>
                            <a class="dropdown-item" href="#">Ver Histórico do Paciente</a>
                            <a class="dropdown-item" href="#">Calibrar Paciente</a>
                            <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_help_request">Enviar
                                pedido de
                                ajuda</a>
                            <a class="dropdown-item" style="color: red;" href="#">Remover Paciente</a>
                        @endslot
                    @endcomponent
                    {{-- dropdown:end --}}
                </td>
            </tr>
        @endslot
    @endcomponent
    {{-- table:end --}}
    @include('modals.modal_add_patient')
    @include('modals.modal_patient_info')
    @include('modals.modal_add_note')
    @include('modals.modal_add_reminder')
    @include('modals.modal_patient_help_request')

@endsection
