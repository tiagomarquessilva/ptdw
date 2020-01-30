{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_past_confs
    @endslot
    @slot('aria_labelledby')
        "Modal de configurações passadas"
    @endslot
    @slot('title')
        Configurações Passadas
    @endslot
    @slot('body')
        <ul class="nav nav-tabs" role="tablist">
            <li class="nav-item">
                <a class="nav-link active" id="past_confs_table_tab" data-toggle="tab" href="#past_confs_table_pane"
                   role="tab"><i class="i-Background mr-1"></i>Tabela</a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="past_confs_graph_tab" data-toggle="tab" href="#past_confs_graph_pane"
                   role="tab"><i
                        class="i-Background mr-1"></i>Gráfico</a>
            </li>
        </ul>
        <div class="tab-content">
            <div class="tab-pane fade show active" id="past_confs_table_pane" role="tabpanel">
                {{-- table:start --}}
                @component('components.table')
                    @slot('table_id')
                        past_confs_table
                    @endslot
                    @slot('title')
                        Lista das Configurações Passadas
                    @endslot
                    @slot('aria_describedby')
                        Tabela com as configurações passadas
                    @endslot
                    @slot('buttons')
                        {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
                    @endslot
                    @slot('search_placeholder')
                        Procurar na Tabela...
                    @endslot
                    @slot('filters')
                    @endslot
                    @slot('thead')
                        <tr>
                            <th>Data</th>
                            <th>BPM Máximo</th>
                            <th>BPM Mínimo</th>
                            <th>EMG Máximo</th>
                            <th>EMG Mínimo</th>
                            <th>Equipamento</th>
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
                                <div class="row">
                                    <div class="col align-self-center align-middle">
                                        @component('components.button_primary')@slot('type')button @endslot
                                        @slot('extra')@endslot
                                        @slot('text')
                                            Usar Configuração
                                        @endslot
                                        @slot('button_id')
                                        @endslot
                                        @endcomponent
                                    </div>
                                </div>
                            </td>
                        </tr>
                    @endslot
                @endcomponent
                {{-- table:end --}}
            </div>
            <div class="tab-pane fade" id="past_confs_graph_pane" role="tabpanel">

            </div>
        </div>
    @endslot
    @slot('buttons')
        {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
    @endslot
@endcomponent
{{-- modal:end --}}
