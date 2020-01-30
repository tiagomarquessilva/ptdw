{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_patient_help_request
    @endslot
    @slot('aria_labelledby')
        Modal para enviar pedido de ajuda
    @endslot
    @slot('title')
        Enviar pedido de ajuda
    @endslot
    @slot('body')
        <form class="" action="/" method="POST" novalidate>
            <h5 class="card-title" style="font-weight: bold">Paciente: <span
                    style="font-weight: normal">Placeholder</span></h5>
            {{-- input_name:start --}}
            <div class="form-group" style="width: 300px">
                @component('components.input_text_email_num_date')
                    @slot('label')
                        Nome:
                    @endslot
                    @slot('input_id')
                        help_request_name
                    @endslot
                    @slot('type')
                        text
                    @endslot
                    @slot('required')
                        required
                    @endslot
                    @slot('placeholder')
                        Inserir nome do pedido de ajuda...
                    @endslot
                    @slot('value')

                    @endslot
                @endcomponent
            </div>
            {{-- input_name:end --}}
            {{-- input_description:start --}}
            <div class="form-group" style="width: 300px">
                @component('components.input_text_area')
                    @slot('input_id')
                        help_request_description
                    @endslot
                    @slot('label')
                        Descrição:
                    @endslot
                    @slot('rows')
                        12
                    @endslot
                    @slot('placeholder')
                        Inserir descrição do pedido de ajuda...
                    @endslot
                    @slot('required')

                    @endslot
                @endcomponent
            </div>
            {{-- input_description:end --}}
            @endslot
            @slot('buttons')
                {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
                {{-- button_primary:start --}}
                @component('components.button_primary')@slot('type')button @endslot
                @slot('extra')
                    type="submit"
                @endslot
                @slot('text')
                    Enviar Pedido de Ajuda
                @endslot
                @slot('button_id')
                    button_send_help_request
                @endslot
                @endcomponent
                {{-- button_primary:end --}}
        </form>
    @endslot
@endcomponent
{{-- modal:end --}}
