@extends('layout.layout')
@section('content')
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            ps_table
        @endslot
        @slot('title')
            Lista de Profissionais de Saúde
        @endslot
        @slot('aria_describedby')
            Lista de Profissionais de Saúde
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            @component('components.button_primary')
                @slot('type')
                @endslot
                @slot('extra')
                    data-toggle="modal" data-target="#modal_add_ps"
                @endslot
                @slot('text')
                    Adicionar Novo Profissional de Saúde
                @endslot
                @slot('button_id')
                    button_add_ps_modal
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
                <th>Tipos</th>
                <th>Função</th>
                <th></th>
            </tr>
        @endslot
        @slot('tbody')
            @foreach($ps_list as $collection => $p)
                <tr class="manage_ps">
                    <td>{{$p['nome']}}</td>
                    <td class="email_ps">{{$p['email']}}</td>
                    <td>{{$p['contacto']}}</td>
                    <td>
                        @foreach($p['tipos'] as $t)
                            <span class="badge badge-primary m-2">{{$t['nome']}}</span>
                        @endforeach
                    </td>
                    <td>
                        @foreach($p['funcao'] as $f)
                            <span>{{$f['nome']}}</span>
                        @endforeach
                    </td>
                    <td>
                        {{-- dropdown:start --}}
                        @component('components.input_dropdown_secondary')
                            @slot('text')
                                Ações
                            @endslot
                            @slot('dropdown_items')
                                <a class="dropdown-item edit_ps" data-toggle="modal"
                                   data-target="#modal_edit_ps_type_function">Editar
                                    Profissional de Saúde</a>
                                <a class="dropdown-item delete_ps" style="color: red;"
                                   data-toggle="modal" data-target="#modal_confirm_del">Remover Profissional de
                                    Saúde</a>
                            @endslot
                        @endcomponent
                        {{-- dropdown:end --}}
                    </td>
                </tr>
            @endforeach
        @endslot
    @endcomponent
    {{-- table:end --}}
    @include('modals.modal_add_ps')
    @include('modals.modal_edit_ps_type_function')
    @include('modals.modal_confirm_del')
    @push('scripts')
        <script src="{{URL::to('/js/custom/ps_list.js')}}"></script>
    @endpush
    @if(session('ps_inserted'))
        @push('scripts')
            <script>
                $(document).ready(function () {
                    toastr.success("O Profissional de Saúde foi inserido com sucesso!", "Profissional de Saúde Inserido");
                });
            </script>
        @endpush
    @endif
    @if(session('ps_updated'))
        @push('scripts')
            <script>
                $(document).ready(function () {
                    toastr.success("O Profissional de Saúde foi alterado com sucesso!", "Profissional de Saúde Alterado");
                });
            </script>
        @endpush
    @endif
    @if(session('ps_deleted'))
        @push('scripts')
            <script>
                if ("{{session('ps_deleted')}}") {
                    $(document).ready(function () {
                        toastr.success("O Profissional de Saúde foi removido com sucesso!", "Profissional de Saúde Removido");
                    });
                } else {
                    $(document).ready(function () {
                        toastr.error("Profissional de Saúde não eliminado!", "Profissional de Saúde Não Eliminado");
                    });
                }
            </script>
        @endpush
    @endif
@endsection
