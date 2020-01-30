{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_add_caretaker
    @endslot
    @slot('aria_labelledby')
        Modal de Adiconar Novo Cuidador
    @endslot
    @slot('title')
        Adicionar Novo Cuidador
    @endslot
    @slot('body')
        <form method="POST" id='add_caretaker' class="needs-validation" novalidate>
            @csrf
            {{-- input_text:start --}}
            @component('components.input_text_email_num_date')
                @slot('input_id')
                    caretaker_name
                @endslot
                @slot('label')
                    Nome:
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                @endslot
                @slot('aria_labelledby')
                    Modal de Adicionar Novo Cuidador
                @endslot
                @slot('title')
                    Adicionar Novo Cuidador
                @endslot
                @slot('body')
                @endslot
                @slot('placeholder')
                    Inserir nome do cuidador...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_text:end --}}
            {{-- input_contact:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    Contacto:
                @endslot
                @slot('input_id')
                    caretaker_contact
                @endslot
                @slot('type')
                    tel
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}

                @endslot
                @slot('placeholder')
                    Inserir contacto do cuidador...
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
                    caretaker_email
                @endslot
                @slot('type')
                    email
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                @endslot
                @slot('placeholder')
                    Inserir e-mail do cuidador...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_email:end --}}
            {{-- input_text:start --}}
            @component('components.input_text_email_num_date')
                @slot('label')
                    Password:
                @endslot
                @slot('input_id')
                    caretaker_password
                @endslot
                @slot('type')
                    password
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                @endslot
                @slot('placeholder')
                    Inserir password do cuidador...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            {{-- input_text:end --}}
            {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Pacientes a cuidar:
                @endslot
                @slot('select_id')
                    caretaker_patients
                @endslot
                @slot('select_name')
                    caretaker_patients[]
                @endslot
                @slot('options')
                    @foreach($patients as $p)
                        <option value="{{$p->id}}">{{$p->nome}}</option>
                    @endforeach
                @endslot
                @slot('multiple')
                    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
                    multiple
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
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
                        Adicionar Cuidador
                    @endslot
                    @slot('button_id')
                        button_add_caretaker
                    @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
