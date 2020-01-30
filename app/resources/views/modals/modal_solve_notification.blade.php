{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_solve_notification
    @endslot
    @slot('aria_labelledby')
        Modal de Resolver Alerta
    @endslot
    @slot('title')
        Resolver Alerta
    @endslot
    @slot('body')
        <form id="solve_notification_form" class="needs-validation" novalidate>
            @method('PUT')
            @csrf
            @component('components.input_switch')
                @slot('label')
                    Resolvido
                @endslot
                @slot('switch_id')
                    solved
                @endslot
                @slot('checked')
                    {{-- Se é para começar ativado com checked se não não colocar nada --}}
                    checked
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent
            <div class="form-group">
                <label for="note">Comentário:</label>
                <textarea class="form-control" name="commentary" id="commentary" form="solve_notification_form"
                          cols="30" rows="10"
                          placeholder="Inserir comentário ao alerta..."></textarea>
            </div>
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
                        button_solve_notification
                    @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
