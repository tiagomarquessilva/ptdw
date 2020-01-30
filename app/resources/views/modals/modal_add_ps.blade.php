{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_add_ps
    @endslot
    @slot('aria_labelledby')
        "Modal de Adicionar Novo Profissional de Saúde"
    @endslot
    @slot('title')
        Adicionar Novo Profissional de Saúde
    @endslot
    @slot('body')
        <form id="add_ps_form" class="needs-validation" novalidate>
            @csrf
            {{-- input_name:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    Nome:
                @endslot
                @slot('input_id')
                    ps_name
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}

                @endslot
                @slot('placeholder')
                    Inserir nome do profissional de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_name:end --}}
            {{-- input_contact:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    Contacto:
                @endslot
                @slot('input_id')
                    ps_contact
                @endslot
                @slot('type')
                    tel
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}

                @endslot
                @slot('placeholder')
                    Inserir contacto do profissional de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_contact:end --}}
            {{-- input_email:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    E-mail:
                @endslot
                @slot('input_id')
                    ps_email
                @endslot
                @slot('type')
                    email
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}

                @endslot
                @slot('placeholder')
                    Inserir e-mail do profissional de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_email:end --}}
            {{-- input_password:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    Password:
                @endslot
                @slot('input_id')
                    ps_password
                @endslot
                @slot('type')
                    password
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}

                @endslot
                @slot('placeholder')
                    Inserir password do profissional de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_password:end --}}
            {{-- select_health_unit:start --}}
            @component('components.input_select')
                @slot('label')
                    Unidade de Saúde:
                @endslot
                @slot('select_id')
                    ps_health_unit
                @endslot
                @slot('select_name')
                    ps_health_unit[]
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
            {{-- select_health_unit:end --}}
            {{-- select_type:start --}}
            @component('components.input_select')
                @slot('label')
                    Tipo:
                @endslot
                @slot('select_id')
                    ps_type
                @endslot
                @slot('select_name')
                    ps_type[]
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
            {{-- select_type:end --}}
            {{-- select_function:start --}}
            @component('components.input_select')
                @slot('label')
                    Função:
                @endslot
                @slot('select_id')
                    ps_function
                @endslot
                @slot('select_name')
                    ps_function
                @endslot
                @slot('options')
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
            {{-- select_function:end --}}
            @endslot
            @slot('buttons')
                {{-- button_primary:start --}}
                @component('components.button_primary')
                    @slot('type')
                    @endslot
                    @slot('extra')
                    @endslot
                    @slot('text')
                        Adicionar Profissional de Saúde
                    @endslot
                    @slot('button_id')
                        button_add_ps
                    @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
