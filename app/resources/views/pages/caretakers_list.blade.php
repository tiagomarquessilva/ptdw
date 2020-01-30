@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            caretakers_table
        @endslot
        @slot('title')
            Lista de Cuidadores
        @endslot
        @slot('aria_describedby')
            Lista de Cuidadores
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @component('components.button_primary')@slot('type')button @endslot
            @slot('extra')
                data-toggle="modal" data-target="#modal_add_caretaker"
            @endslot
            @slot('text')
                Adicionar Novo Cuidador
            @endslot
            @slot('button_id')
                button_add_caretaker_modal
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
                <th>E-mail</th>
                <th>Contacto</th>
                <th>Unidades de Saúde</th>
                <th>Pacientes a cuidar</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            @foreach ($caretakers as $collection => $c)
                <tr>
                    <td>{{$c['name']}}</td>
                    <td>{{$c['email']}}</td>
                    <td>{{$c['contact']}}</td>
                    <td>
                        @foreach($c['health_units'] as $h)
                            <span class="badge badge-primary m-2">{{$h['nome']}}</span>
                        @endforeach
                    </td>
                    <td>
                        @foreach ($c['patients'] as $collection => $p)
                            <span class="badge badge-primary m-2">{{$p['nome']}}</span>
                        @endforeach
                    </td>
                    <td>
                        {{-- dropdown:start --}}
                        @component('components.input_dropdown_secondary')
                            @slot('text')
                                Ações
                            @endslot
                            @slot('dropdown_items')
                                <a class="dropdown-item" data-toggle="modal"
                                   data-target="#modal_edit_caretaker_patients">Editar Pacientes do Cuidador</a>
                                <a class="dropdown-item" style="color: red;" href="#">Remover Cuidador</a>
                            @endslot
                        @endcomponent
                        {{-- dropdown:end --}}
                    </td>
                </tr>
            @endforeach
        @endslot
    @endcomponent
    {{-- table:end --}}
    @include('modals.modal_add_caretaker')

    @push('scripts')
        <script src="{{URL::to('/js/custom/caretakers_list.js')}}"></script>
    @endpush
    @if(session('c_inserted'))
        @push('scripts')
            <script>
                $(document).ready(function () {
                    toastr.success("O Cuidador foi inserido com sucesso!", "Cuidador Inserido");
                });
            </script>
        @endpush
    @endif
@endsection
