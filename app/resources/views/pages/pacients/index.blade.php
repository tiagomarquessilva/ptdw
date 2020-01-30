@extends('layout.layout')
@section('content')
{{-- table:start --}}
@component('components.table')
@slot('table_id')
patients_table
@endslot
@slot('title')
Lista de Pacientes
@endslot
@slot('aria_describedby')
Lista de pacientes
@endslot
@slot('buttons')
    @if (Auth::user()->temTipos([config('Utilizador_Tipo.2')]))
{{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
@component('components.button_primary')
@slot('extra')
data-toggle="modal" data-target="#modal_add_patient"
@endslot
@slot('type')
button
@endslot
@slot('text')
Adicionar Novo Paciente
@endslot
@slot('button_id')
button_add_patient_modal
@endslot
@endcomponent
@endif
@endslot
@slot('search_placeholder')
Procurar na Tabela...
@endslot
@slot('filters')
{{-- dropdown:start --}}
@component('components.input_dropdown_secondary')
@slot('text')
Filtros
@endslot
@slot('dropdown_items')
<div class="dropdown-item">
    @component('components.input_text_email_num_date')
    @slot('label')
    Exemplo Filtro:
    @endslot
    @slot('input_id')
    input
    @endslot
    @slot('type')
    text
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    @endslot
    @slot('placeholder')
    Procurar
    @endslot
    @slot('value')
    @endslot
    @endcomponent
</div>
@endslot
@endcomponent
{{-- dropdown:end --}}
@endslot
@slot('thead')
<tr>
    <th hidden>Id</th>
    <th>Nome</th>
    <th>Género</th>
    <th>Doença</th>
    <th>Data de nascimento</th>
    <th>Data de diagnóstico</th>
    <th>Músculo onde colocar o sensor</th>
    <th></th>
</tr>
@endslot
@slot('tbody')
    @foreach ($pacientes as $paciente)
        <tr>
            <td hidden>{{$paciente->id}}</td>
            <td>{{$paciente->nome}}</td>
            <td>{{$paciente->sexo}}</td>
            <td>{{$paciente->doencas}}</td>
            <td>{{date('d/m/Y',strtotime($paciente->data_nascimento))}}</td>
            <td>{{date('d/m/Y',strtotime($paciente->data_diagnostico))}}</td>
            <td>{{$paciente->musculos}}</td>
            <td>
                {{-- dropdown:start --}}
                @component('components.input_dropdown_secondary')
                @slot('text')
                Ações
                @endslot
                @slot('dropdown_items')
                <a class="dropdown-item" href="{{URL::to('/lista_de_pacientes')}}" data-info data-toggle="modal" data-target="#modal_patient_info">Ver Informações do Paciente</a>

                @if (Auth::user()->temTipos([config('Utilizador_Tipo.2')]))
                <a class="dropdown-item" data-edit data-toggle="modal" data-target="#modal_edit_patient">Editar Informações do Paciente</a>
                <!--a class="dropdown-item" href="#">Ver Histórico do Paciente</a>
                <a class="dropdown-item" href="#">Calibrar Paciente</a>
                <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_help_request">Enviar pedido de
                    ajuda</a-->
                <a id="remove_patient" class="dropdown-item" style="color: red;" href="#">Remover Paciente</a>
                @endif
                @endslot
                @endcomponent
                {{-- dropdown:end --}}
            </td>
        </tr>
    @endforeach
@endslot
@endcomponent
{{-- table:end --}}
@include('modals.modal_add_patient')
@include('modals.modal_edit_patient')
@include('modals.modal_patient_info')
@include('modals.modal_add_note')
@include('modals.modal_add_reminder')
@include('modals.modal_patient_help_request')




@push("scripts")
<script>
    let pacient;
    $(document).ready(function(){
        // TODO: Modify these datepickers to a helper function in order to avoid repetition.
        // this was needed in order to have the date input fields show the date in a needed format
        $("#patient_birth_date_edit").datepicker({
            locale: 'pt',
            format: 'dd/mm/yyyy'
        });

        $("#patient_diagnosis_date_edit").datepicker({
            locale: 'pt',
            format: 'dd/mm/yyyy'
        });

        $("#patient_diagnosis_date").datepicker({
            locale: 'pt',
            format: 'dd/mm/yyyy'
        });

        $("#patient_birth_date").datepicker({
            locale: 'pt',
            format: 'dd/mm/yyyy'
        });
        $('#modal_patient_info').on('hidden.bs.modal', function () {
                alert("cenas");
                $('#notes_table').DataTable().row().remove().draw();
                $('#reminders_table').DataTable().row().remove().draw();
            });
        // TODO: this should be done at the Datatable component definition level so its
        // uniform to everyone. The purpose here is to hide the ID column but its still important
        // to get it from the controller in order to manipulate the record at will.
        $('#patients_table').DataTable().column( 0 ).visible( false );

        // listener that checks clicks on the patient table when the user clicks in the edit button
        // this is here and not in the edit modal view because a modal is just a layer, the html beneath is still here to comand
        // Remember this is for filling the edit form with the current patient info.
        $(document).on('click', '#patients_table [data-edit]',function () {
            let table = $('#patients_table').DataTable();
            patient = table.row(this.closest("tr"));
            let patient_info = patient.data();
            let diseases = patient_info[3].split(','); // information related to the diseases. It might be more than one
            let muscles = patient_info[6].split(','); // information related to the muscles. It might be more than one
            if (diseases.length > 1){
                $("#patient_disease_edit").val(diseases).trigger('change');
            }else{
                $("#patient_disease_edit").val(patient_info[3]).trigger('change');
            }
            if (muscles.length > 1){
                $("#patient_muscle_edit").val(muscles).trigger('change');
            }else{
                $("#patient_muscle_edit").val(patient_info[6]).trigger('change');
            }
            $("#patient_name_edit").val(patient_info[1]);
            $("#patient_gender_edit").val(patient_info[2]).trigger('change');
            $("#patient_birth_date_edit").val(patient_info[4]);
            $("#patient_diagnosis_date_edit").val(patient_info[5]);
            $("#patient_id").val(patient_info[0]);
        });

        // listener that checks clicks on the patient table when the user clicks in the info details button
        // this is here and not in the edit modal view because a modal is just a layer, the html beneath is still here to comand
        // Remember this is for filling the info details form with the current patient info.
        // TODO: change the patient_info array into variables with more intuitive names and that can be used globally in this function
        $(document).on('click', '#patients_table [data-info]',function () {
            let table = $('#patients_table').DataTable();
            patient = table.row(this.closest("tr"));
            let patient_info = patient.data();
            console.log("cenas", patient_info);
            let diseases = patient_info[3].split(',');
            let muscles = patient_info[6].split(',');
            if (diseases.length > 1){
                $("#patient_disease_info").text(diseases);
            }else{
                $("#patient_disease_info").text(patient_info[3]);
            }
            if (muscles.length > 1){
                $("#patient_muscle_info").text(muscles);
            }else{
                $("#patient_muscle_info").text(patient_info[6]);
            }
            $("#patient_name_info").text(patient_info[1]);
            $("#patient_gender_info").text(patient_info[2]);
            $("#patient_birth_date_info").text(patient_info[4]);
            $("#patient_diagnosis_info").text(patient_info[5]);
            $("#patient_id_info").val(patient_info[0]);

            // this ajax request needs to be here, because this is where the datatable lives and where
            // we can listen to events without losing scope.
            $("#paciente_id").val(patient_info[0]);
            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                url: "{{URL::to('/notas')}}" + "/" + patient_info[0],
                dataType: 'json',
                data: {
                    id: patient_info[0]
                },
                statusCode: {
                    422: function (resposta) {
                    }
                },
                success: function(data)
                {
                    let t = $('#notes_table').DataTable();
                        data.note.forEach(element => {
                            t.row.add([
                                element.id,
                                element.nome,
                                element.descricao,
                                `<button type="button" class="btn btn-raised btn-raised-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Ações</button>
                                <div class="dropdown-menu" x-placement="bottom-start">
                                <button id="remove_note" class="dropdown-item" style="color: red;">Remover Nota</button></div>`
                            ]).draw();
                        });
                }
            });



            // this ajax request needs to be here, because this is where the datatable lives and where
            // we can listen to events without losing scope.
            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",

                url: "{{URL::to('/lembretes')}}" + "/" + patient_info[0],
                dataType: 'json',
                data: {
                    id: patient_info[0]
                },
                statusCode: {
                    422: function (resposta) {
                        console.table(resposta)
                    }
                },
                success: function(data)
                {
                    let t = $('#reminders_table').DataTable();
                        data.note.forEach(element => {
                            t.row.add([
                                element.id,
                                element.nome,
                                element.created_at,
                                element.criado_por,
                                `<button type="button" class="btn btn-raised btn-raised-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Ações</button>
                                <div class="dropdown-menu" x-placement="bottom-start">
                                <button id="remove_note" class="dropdown-item" style="color: red;">Remover Lembrete</button></div>`
                            ]).draw();
                        });
                }
            });

        });

        $(document).on('hide.bs.modal', '#modal_patient_info', function () {
            $('#notes_table').DataTable().row().remove().draw();
            $('#reminders_table').DataTable().row().remove().draw();
        });

        $(document).on('hidden.bs.modal', '#modal_patient_info', function () {
            $('#notes_table').DataTable().row().remove().draw();
            $('#reminders_table').DataTable().row().remove().draw();
        });

        $('#button_add_patient_modal').on('click', function(){
            cleanModalForm();
        })

        // Again this is here because it was losing scope in the own modal view. Thus here is always a guarantee to work.
        $('#button_add_note').on('click', function () {
            const form = $("#add_note");
            const url = form.attr('action');

            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                url: url,
                dataType: 'json',
                data: form.serialize(),
                statusCode: {
                    422: function (resposta) {
                    }
                },
                success: function(data)
                {

                    if($.isEmptyObject(data.error)) {
                        let note = data.note;
                        let t = $('#notes_table').DataTable();
                        t.row.add([
                            note.id,
                            note.nome,
                            note.descricao,
                            `<button type="button" class="btn btn-raised btn-raised-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Ações</button>
                            <div class="dropdown-menu" x-placement="bottom-start">
                                <button id="remove_note" class="dropdown-item" style="color: red;">Remover Nota</button></div>`
                        ]).draw();
                        $('#modal_add_note').modal('hide');
                        cleanModalForm();
                    }
                }
            });
        });

        // Again this is here because it was losing scope in the own modal view. Thus here is always a guarantee to work.
        $('#button_add_reminder_modal').on('click', function () {
            const form = $("#add_remainder");
            const url = form.attr('action');
            console.log("form", form.serialize());
            console.log("url", url);
            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                url: url,
                dataType: 'json',
                data: form.serialize(),
                statusCode: {
                    422: function (resposta) {
                    }
                },
                success: function(data)
                {
                    if($.isEmptyObject(data.error)) {
                        let reminder = data.reminder;
                        let t = $('#reminders_table').DataTable();
                        t.row.add([
                            reminder.id,
                            reminder.nome,
                            reminder.data_a_notificar,
                            reminder.hora_a_notificar,
                            `<button type="button" class="btn btn-raised btn-raised-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Ações</button>
                            <div class="dropdown-menu" x-placement="bottom-start">
                                <button id="remove_remainder" class="dropdown-item" style="color: red;">Remover Lembrete</button></div>`
                        ]).draw();
                        $('#modal_add_reminder').modal('hide');
                        cleanModalForm();
                    }
                }
            });
        });

        // Remember remove a patient is to update its active value to False.
        $(document).on("click", "#remove_patient", function(e){
            let $button = $(this);
            let table = $('#patients_table').DataTable();
            patient = table.row(this.closest("tr"));
            let patient_info = patient.data();
            let patient_id = patient_info[0];

            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",

                url: "{{URL::to('/eliminar_paciente')}}" + "/" + patient_id,
                dataType: 'json',
                data: {
                    id: patient_id
                },
                statusCode: {
                    422: function (resposta) {
                    }
                },
                success: function(data)
                {
                    $('#patients_table').DataTable().row($button.parents('tr')).remove().draw();
                }
            });
            e.preventDefault();
        });
    });

    function cleanModalForm(){
        $("#create_form_patient")[0].reset();
        $("#patient_disease").val('').trigger('change');
        $("#patient_muscle").val('').trigger('change');
    }

    // Prints the errors while form filling
    function printErrorMsg(msg) {
        $('.print-error-msg').find('ul').html('');
        $('.print-error-msg').css('display','block');
        $.each(msg, function(key,value){
            $('.print-error-msg').find('ul').append('<li>'+value+'</li>');
        });
    }
</script>
@endpush
@endsection

