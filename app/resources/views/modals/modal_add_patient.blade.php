{{-- modal:start --}}
@component('components.modal')
@slot('id')
modal_add_patient
@endslot
@slot('aria_labelledby')
"Modal de Adiconar Novo Paciente"
@endslot
@slot('title')
Adicionar Novo Paciente
@endslot
@slot('body')
<div class="alert alert-danger print-error-msg" style="display:none">
    <ul></ul>
</div>
<form id="create_form_patient" action="{{URL::to('/criar_paciente')}}" method="POST" novalidate>
    {{-- input_text:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Nome:
    @endslot
    @slot('input_id')
    patient_name
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
    patient_gender
    @endslot
    @slot('select_name')
    patient_gender
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
    patient_birth_date
    @endslot
    @slot('type')
    text
    @endslot
    @slot('date_format')
    dd/mm/yyyy
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
    patient_disease
    @endslot
    @slot('options') {{--#TODO: Tornar isto dinâmico a ir buscar os valores à tabela doenca ou um enumerado previamente preenchido --}}
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
    patient_diagnosis_date
    @endslot
    @slot('type')
    text
    @endslot
    @slot('date_format')
    dd/mm/yyyy
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
    patient_muscle
    @endslot
    @slot('options'){{--#TODO: Tornar isto dinâmico a ir buscar os valores à tabela musculos ou enumerado previamente preenchidos --}}
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
    @slot('type')
    button
    @endslot
    @slot('extra')
    type="submit"
    @endslot
    @slot('text')
    Adicionar Paciente
    @endslot
    @slot('button_id')
    button_add_patient
    @endslot
    @endcomponent
    {{-- button_primary:end --}}
</form>
@endslot
@endcomponent
{{-- modal:end --}}
<script>
    $(document).ready(function(){
        $("#button_add_patient").on("click", function(e){
            const form = $("#create_form_patient");
            console.log("form",form.serialize());
            const url = form.attr('action');
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
                    if(data.status == 'ok'){
                        $('#modal_edit_patient').modal('hide');
                        var url = "{{URL::to('/')}}" + data.redirect;
                        $(location).attr('href', url);
                    }
                    /*
                    if($.isEmptyObject(data.error)) {

                        let patient = data.patient;
                        let muscle  = data.muscle;
                        let disease = data.disease;
                        let t = $('#patients_table').DataTable();
                        let birth_date = new Date(patient.data_nascimento);
                        let diagnosis_date = new Date(patient.data_diagnostico);
                        birth_date = birth_date.getDate() + "/" + (birth_date.getMonth() + 1) + "/" + birth_date.getFullYear();

                        diagnosis_date = diagnosis_date.getDate() + "/" + (diagnosis_date.getMonth() + 1) + "/"
                        + diagnosis_date.getFullYear();

                        t.row.add([
                            patient.id,
                            patient.nome,
                            patient.sexo,
                            disease,
                            birth_date,
                            diagnosis_date,
                            muscle,
                            `<button type="button" class="btn btn-raised btn-raised-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Ações</button>
                            <div class="dropdown-menu" x-placement="bottom-start">
                                <a class="dropdown-item" data-toggle="modal" data-target="#modal_patient_info">Ver Informações do Paciente</a>
                                <a class="dropdown-item" data-edit data-toggle="modal" data-target="#modal_edit_patient">Editar Informações do Paciente</a>
                                <a id="remove_patient" class="dropdown-item" style="color: red;" href="">Remover Paciente</a></div>`
                        ]).draw();
                        $('#modal_add_patient').modal('hide');
                        cleanModalForm();

                        } */
                    else{
                        printErrorMsg(data.error);
                    }
                }
            });
            e.preventDefault();
        });

        // Removes the div with the form errors
        $("#dismiss_modal").on("click", function(e){
            cleanModalForm();
            $('.print-error-msg').css('display','none');
            e.preventDefault();
        });

        $('#modal_patient_info').on('hidden.bs.modal', function () {
            cleanModalForm();
            $('.print-error-msg').css('display','none');
            e.preventDefault();
        });

        // Cleans the form if the user closes the form modal while filling it by chance or because he/she meant to.
        //TODO: this should be made as an helper function like an utility and imported as such to avoid repetition.
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
    });
</script>
