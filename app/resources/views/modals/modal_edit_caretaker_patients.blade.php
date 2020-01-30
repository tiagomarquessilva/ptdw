{{-- modal:start --}}
@component('components.modal')
    @slot('id')
        modal_edit_caretaker_patients
    @endslot
    @slot('aria_labelledby')
        "Modal de edição de pacientes do cuidador"
    @endslot
    @slot('title')
        Editar Pacientes do Cuidador
    @endslot
    @slot('body')
        <form action="" method="post">
            {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Atribuir Paciente:
                @endslot
                @slot('select_id')
                    add_patient_to_caretaker
                @endslot
                @slot('select_name')
                    add_patient_to_caretaker
                @endslot
                @slot('options')
                    <option value="AL">Alabama</option>
                    <option value="WY">Wyoming</option>
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
            <span class="t-font-boldest">Pacientes Atríbuidos:</span>
            @component('components.list')
                @slot('items')
                    <li class="list-group-item">
                        <div class="row">
                            <div class="col text-left">
                                Clotilde
                            </div>
                            <div class="col text-right">
                                <i class="i-Background"></i>
                            </div>
                        </div>
                    </li>
                    <li class="list-group-item">
                        <div class="row">
                            <div class="col text-left">
                                Clotilde
                            </div>
                            <div class="col text-right">
                                <i class="i-Background"></i>
                            </div>
                        </div>
                    </li>
                    <li class="list-group-item">
                        <div class="row">
                            <div class="col text-left">
                                Clotilde
                            </div>
                            <div class="col text-right">
                                <i class="i-Background"></i>
                            </div>
                        </div>
                    </li>
                @endslot
            @endcomponent
            @endslot
            @slot('buttons')
                {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
                @component('components.button_primary')
                    @slot('extra')@endslot
                    @slot('text')
                        Guardar Alterações
                    @endslot
                    @slot('button_id')
                        button_edit_caretaker_patients
                    @endslot
                @endcomponent
        </form>
    @endslot
    @slot('required')
        {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    @endslot
@endcomponent
{{-- select:end --}}
<span class="t-font-boldest">Pacientes Atríbuidos:</span>
@component('components.list')
    @slot('items')
        <li class="list-group-item">
            <div class="row">
                <div class="col text-left">
                    Clotilde
                </div>
                <div class="col text-right">
                    <i class="i-Background"></i>
                </div>
            </div>
        </li>
        <li class="list-group-item">
            <div class="row">
                <div class="col text-left">
                    Clotilde
                </div>
                <div class="col text-right">
                    <i class="i-Background"></i>
                </div>
            </div>
        </li>
        <li class="list-group-item">
            <div class="row">
                <div class="col text-left">
                    Clotilde
                </div>
                <div class="col text-right">
                    <i class="i-Background"></i>
                </div>
            </div>
        </li>
    @endslot
@endcomponent
@endslot
@slot('buttons')
    {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
    @component('components.button_primary')@slot('type')button @endslot
    @slot('extra')@endslot
    @slot('text')
        Guardar Alterações
    @endslot
    @slot('button_id')
        button_edit_caretaker_patients
        @endslot
        @endcomponent
        </form>
    @endslot
    @endcomponent
    {{-- modal:end --}}
