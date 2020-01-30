{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_confirm_del
    @endslot
    @slot('aria_labelledby')
        Modal de Confirmação de Eliminação
    @endslot
    @slot('title')
        Atenção!
    @endslot
    @slot('body')
        <p>
            Ao clicar em "Eliminar" este registo será apagado.
        </p>
        <p>
            Esta ação é <b>irreversível</b>!
        </p>
    @endslot
    @slot('buttons')
        {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
        <form action="" method="POST" id="confirm_del_form" style="display: inline;">
            @method("DELETE")
            @csrf
            {{-- button_danger:start --}}
            @component('components.button_danger')
                @slot('type')
                @endslot
                @slot('extra')
                @endslot
                @slot('text')
                    Eliminar
                @endslot
                @slot('button_id')
                    button_confirm_del
                @endslot
            @endcomponent
            {{-- button_danger:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
