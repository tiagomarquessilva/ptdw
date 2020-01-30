{{-- modal:start --}}
@component('components.modal')
@slot('id')
modal_patient_info
@endslot
@slot('aria_labelledby')
Modal com Informações Pessoais do Paciente
@endslot
@slot('title')
Informações de Paciente
@endslot
@slot('body')
<div class="row">
    <div class="col-4">
        @component('components.card')
        @slot('title')
        <div class="row">
            <div class="col-10">
                Informações Pessoais
            </div>
        </div>
        @endslot
        @slot('body')
        <div class="ul-contact-detail__info">
            <div class="row">
                <input id="patient_id_info" name="patient_id_info" value="" hidden/>
                <div class="col-6 text-center">
                    <div class="ul-contact-detail__info-1">
                        <h5>Nome</h5>
                        <span id="patient_name_info">John Doe</span>
                    </div>
                    <div class="ul-contact-detail__info-1">
                        <h5>Género</h5>
                        <span id="patient_gender_info">Masculino</span>
                    </div>
                </div>
                <div class="col-6 text-center">
                    <div class="ul-contact-detail__info-1">
                        <h5>Data de Nascimento</h5>
                        <span id="patient_birth_date_info">01/01/01</span>
                    </div>
                    <div class="ul-contact-detail__info-1">
                        <h5>Músculo</h5>
                        <span id="patient_muscle_info">Bochecha Direita</span>
                    </div>
                </div>
                <div class="col-6 text-center">
                    <div class="ul-contact-detail__info-1">
                        <h5>Doenças</h5>
                        <span id="patient_disease_info">ELA, Paralisisa</span>
                    </div>
                </div>
                <div class="col-6 text-center">
                    <div class="ul-contact-detail__info-1">
                        <h5>Data de Diagnóstico</h5>
                        <span id="patient_diagnosis_info">01/01/01</span>
                    </div>
                </div>
            </div>
        </div>
        @endslot
        @endcomponent
    </div>
    <div class="col-8">
        {{-- table:start --}}
        @component('components.table')
        @slot('table_id')
        notes_table
        @endslot
        @slot('title')
        Notas de Paciente
        @endslot
        @slot('aria_describedby')
        Tabela com as notas de paciente
        @endslot
        @slot('buttons')
        {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
        @component('components.button_primary')
        @slot('extra')
        data-toggle="modal" data-target="#modal_add_note"
        @endslot
        @slot('type')
        button
        @endslot
        @slot('text')
        Adicionar Nota
        @endslot
        @slot('button_id')
        button_add_note_modal
        @endslot
        @endcomponent
        @endslot
        @slot('search_placeholder')
        Procurar na Tabela...
        @endslot
        @slot('filters')
        @endslot
        @slot('thead')
        <tr>
            <th>Id</th>
            <th>Título</th>
            <th>Nota</th>
            <th></th>
        </tr>
        @endslot
        @slot('tbody')

        @endslot
        @endcomponent
        {{-- table:end --}}
    </div>
    <div class="col-8">
        {{-- table:start --}}
        @component('components.table')
        @slot('table_id')
        reminders_table
        @endslot
        @slot('title')
        Lembretes
        @endslot
        @slot('aria_describedby')
        Tabela com os lembretes de paciente
        @endslot
        @slot('buttons')
        {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
        @component('components.button_primary')
        @slot('extra')
        data-toggle="modal" data-target="#modal_add_reminder"
        @endslot
        @slot('type')
        button
        @endslot
        @slot('text')
        Adicionar Lembrete
        @endslot
        @slot('button_id')
        button_add_reminder_modal
        @endslot
        @endcomponent
        @endslot
        @slot('search_placeholder')
        Procurar na Tabela...
        @endslot
        @slot('filters')
        @endslot
        @slot('thead')
        <tr>
            <th>Lembrete</th>
            <th>Data para Notificar</th>
            <th>Horas</th>
            <th></th>
        </tr>
        @endslot
        @slot('tbody')
        @endslot
        @endcomponent
        {{-- table:end --}}
    </div>
</div>
@endslot
@slot('buttons')
{{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
@endslot
@endcomponent
{{-- modal:end --}}
@push("scripts")
<script>
    $(document).ready(function(){

        $(document).on("click", '#remove_note', function(e){
            let $button = $(this);
            let table = $('#notes_table').DataTable();
            note = table.row(this.closest("tr"));
            let note_info = note.data();
            let note_id = note_info[0];
            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                
                url: "{{URL::to('/eliminar_nota')}}"+'/'+note_id,
                dataType: 'json',
                data: {
                    id: note_id
                },
                statusCode: {
                    422: function (resposta) {
                        console.table(resposta)
                    }
                },
                success: function(data)
                {
                    $('#notes_table').DataTable().row($button.parents('tr')).remove().draw();
                }
            });
            e.preventDefault();
        });

        $(document).on("click", '#remove_remainder', function(e){
            let $button = $(this);
            let table = $('#reminders_table').DataTable();
            remainder = table.row(this.closest("tr"));
            let remainder_info = remainder.data();
            let remainder_id = remainder_info[0];
            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                url: '/eliminar_lembrete/'+remainder_id,
                dataType: 'json',
                data: {
                    id: remainder_id
                },
                statusCode: {
                    422: function (resposta) {
                    }
                },
                success: function(data)
                {
                    $('#reminders_table').DataTable().row($button.parents('tr')).remove().draw();
                }
            });
            e.preventDefault();
        });

        $(document).on('hide.bs.modal', '#modal_patient_info', function () {
            $('#notes_table').DataTable().row().remove().draw();
            $('#reminders_table').DataTable().row().remove().draw();
        });
    });
</script>
@endpush
