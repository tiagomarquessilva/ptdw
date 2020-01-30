{{-- modal:start --}}
@component('components.modal')
@slot('id')
modal_edit_patient
@endslot
@slot('aria_labelledby')
"Modal de Editar Paciente"
@endslot
@slot('title')
Editar Informações do Paciente
@endslot
@slot('body')
<div class="alert alert-danger print-error-msg" style="display:none">
    <ul></ul>
</div>
<form id="edit_form_patient" action="{{URL::to('/editar_paciente')}}" method="POST" novalidate>
    {{-- input_text:start --}}
    <input type="hidden" id="patient_id" name="patient_id">
    @component('components.input_text_email_num_date')
    @slot('label')
    Nome:
    @endslot
    @slot('input_id')
    patient_name_edit
    @endslot
    @slot('type')
    text
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    Inserir nome do paciente...
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_text:end --}}
    {{-- select:start --}}
    @component('components.input_select')
    @slot('label')
    Género:
    @endslot
    @slot('select_id')
    patient_gender_edit
    @endslot
    @slot('select_name')
    patient_gender_edit
    @endslot
    @slot('options')
    <option value="m">Masculino</option>
    <option value="f">Feminino</option>
    @endslot
    @slot('multiple')
    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @endcomponent
    {{-- select:end --}}
    {{-- input_date:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Data de nascimento:
    @endslot
    @slot('input_id')
    patient_birth_date_edit
    @endslot
    @slot('type')
    text
    @endslot
    @slot('date_format')
    dd/mm/yy
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    dd/mm/yyyy
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_date:end --}}
    {{-- select:start --}}
    @component('components.input_select_old')
    @slot('label')
    Doença:
    @endslot
    @slot('select_id_and_name')
    patient_disease_edit
    @endslot
    @slot('options') {{--#TODO: Tornar isto dinâmico a ir buscar os valores à tabela doenca --}}
    <option value="ELA">ELA</option>
    <option value="Paralisia Cerebral">Paralisia Cerebral</option>
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
    {{-- input_date:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Data de diagnóstico:
    @endslot
    @slot('input_id')
    patient_diagnosis_date_edit
    @endslot
    @slot('type')
    text
    @endslot
    @slot('date_format')
    dd/mm/yy
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    dd/mm/yyyy
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_date:end --}}
    {{-- select:start --}}
    @component('components.input_select_old')
    @slot('label')
    Músculo a colocar o sensor:
    @endslot
    @slot('select_id_and_name')
    patient_muscle_edit
    @endslot
    @slot('options'){{--#TODO: Tornar isto dinâmico a ir buscar os valores à tabela musculos --}}
    <option value="Bochecha Esquerda">Bochecha Esquerda</option>
    <option value="Bochecha Direita">Bochecha Direita</option>
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
    @slot('extra')
    type="submit"
    @endslot
    @slot('type')
    button
    @endslot
    @slot('text')
    Guardar Alterações
    @endslot
    @slot('button_id')
    button_edit_patient
    @endslot
    @endcomponent
    {{-- button_primary:end --}}
</form>
@endslot
@endcomponent
{{-- modal:end --}}
<script>
    $(document).ready(function(){

        $("#button_edit_patient").on("click", function(e)
        {
            const form = $("#edit_form_patient");
            const url = form.attr('action')+"/"+$("#patient_id").val();

            $.ajax({
                headers: {
                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                },
                type: "POST",
                url: url,
                dataType: 'json',
                data: form.serialize(), // serializes the form's elements.
                success: function(data)
                {
                    //TODO: this needs a loading spinner so that the user is presented with
                    // a loading icon while the refresh is taking place
                    if(data.status == 'ok'){
                        $('#modal_edit_patient').modal('hide');
                        var url = "{{URL::to('/')}}" + data.redirect;
                        $(location).attr('href', url);
                    }
                    /*
                    let table = $('#patients_table').DataTable();
                    let birth_date = new Date(data.patient.data_nascimento);
                    let diagnosis_date = new Date(data.patient.data_diagnostico);
                    birth_date = birth_date.getDate() + "/" + (birth_date.getMonth() + 1) + "/" + birth_date.getFullYear();

                    diagnosis_date = diagnosis_date.getDate() + "/" +
                        (diagnosis_date.getMonth() + 1) + "/" + diagnosis_date.getFullYear();

                    if($.isEmptyObject(data.error)) {
                        let tr = $('#patients_table tbody tr:eq('+patient.index()+')');
                            tr.find('td:eq(3)').html(data.disease);
                            tr.find('td:eq(6)').html(data.muscle);
                            tr.find('td:eq(1)').html(data.patient.nome);
                            tr.find('td:eq(2)').html(data.patient.sexo);
                            tr.find('td:eq(4)').html(birth_date);
                            tr.find('td:eq(5)').html(diagnosis_date);
                            table.rows(patient.index()).draw();
                    $('#modal_edit_patient').modal('hide');
                    } */
                    else{
                        printErrorMsg(data.error);
                    }
                }
            });
            e.preventDefault();
        });

        $("#dismiss_modal").on("click", function(e){
            cleanModalForm();
            $('.print-error-msg').css('display','none');
            e.preventDefault();
        });

        function cleanModalForm(){
            $("#create_form_patient")[0].reset();
            $("#patient_disease").val('').trigger('change');
            $("#patient_muscle").val('').trigger('change');
        }

        function printErrorMsg(msg) {
            $('.print-error-msg').find('ul').html('');
            $('.print-error-msg').css('display','block');
            $.each(msg, function(key,value){
                $('.print-error-msg').find('ul').append('<li>'+value+'</li>');
            });
        }
    });
</script>
