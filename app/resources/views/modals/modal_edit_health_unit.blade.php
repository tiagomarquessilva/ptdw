{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_edit_health_unit
    @endslot
    @slot('aria_labelledby')
        Modal de Editar Unidade de Saúde
    @endslot
    @slot('title')
        Editar Unidade de Saúde
    @endslot
    @slot('body')
        <form id="edit_health_unit_form" class="needs-validation" novalidate>
            @method('PUT')
            @csrf
            @component('components.input_text_email_num_date')
                @slot('label')
                    Nome:
                @endslot
                @slot('input_id')
                    edit_health_unit_name
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir novo nome da unidade de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            @component('components.input_text_email_num_date')
                @slot('label')
                    Morada:
                @endslot
                @slot('input_id')
                    edit_health_unit_address
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir nova morada da unidade de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            @component('components.input_text_email_num_date')
                @slot('label')
                    Contacto:
                @endslot
                @slot('input_id')
                    edit_health_unit_contact
                @endslot
                @slot('type')
                    number
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir novo contacto da unidade de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            @component('components.input_text_email_num_date')
                @slot('label')
                    E-mail:
                @endslot
                @slot('input_id')
                    edit_health_unit_email
                @endslot
                @slot('type')
                    email
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir novo e-mail da unidade de saúde...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
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
                        button_edit_health_unit
                    @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
