{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_edit_ps_type_function
    @endslot
    @slot('aria_labelledby')
        "Modal de Editar Tipo e Funções do Profissional de Saúde"
    @endslot
    @slot('title')
        Editar Tipo e Funções de Profissional de Saúde
    @endslot
    @slot('body')
        <form novalidate id="edit_ps_form" class="needs-validation" novalidate>
            @method('PUT')
            @method('DELETE')
            @csrf
            {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Unidade de Saúde:
                @endslot
                @slot('select_id')
                    edit_ps_health_unit
                @endslot
                @slot('select_name')
                    edit_ps_health_unit[]
                @endslot
                @slot('options')
                    @foreach($health_unit as $h)
                        <option value="{{$h->id}}">{{$h->nome}}</option>
                    @endforeach
                @endslot
                @slot('multiple')
                    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
                    multiple
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent
            {{-- select:end --}}
            {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Tipo:
                @endslot
                @slot('select_id')
                    edit_ps_type
                @endslot
                @slot('select_name')
                    edit_ps_type[]
                @endslot
                @slot('options')
                    @foreach($types as $t)
                        <option value="{{$t->id}}">{{$t->nome}}</option>
                    @endforeach
                @endslot
                @slot('multiple')
                    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
                    multiple
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent
            {{-- select:end --}}
            {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Função:
                @endslot
                @slot('select_id')
                    edit_ps_function
                @endslot
                @slot('select_name')
                    edit_ps_function[]
                @endslot
                @slot('options')
                    <option value="default" disabled selected>Selecione uma função</option>
                    @foreach($ps_functions as $f)
                        <option value="{{$f->id}}">{{$f->nome}}</option>
                    @endforeach
                @endslot
                @slot('multiple')
                    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent
            {{-- select:end --}}
            @endslot
            @slot('buttons')
                {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
                {{-- button_primary:start --}}
                @component('components.button_primary')
                    @slot('type')
                    @endslot
                    @slot('extra')
                    @endslot
                    @slot('text')
                        Guardar Alterações
                    @endslot
                    @slot('button_id')
                        button_edit_ps_type_function
                    @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
