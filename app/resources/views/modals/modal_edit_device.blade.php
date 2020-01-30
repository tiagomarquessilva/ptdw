{{-- modal:start --}}
@component('components.modal')
@slot('id')
modal_edit_device
@endslot
@slot('aria_labelledby')
Modal de Editar Equipamento
@endslot
@slot('title')
Editar Equipamento
@endslot
@slot('body')
<form id="editar_equipamento" action="{{URL::to('/equipamento')}}" method="POST" novalidate>
    @csrf
    @method('patch')
    <input type="hidden" id="id" name="id">
            @component('components.input_text_email_num_date')
                @slot('label')
                    Nome do Equipamento:
                @endslot
                @slot('input_id')
                    nome_edit
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir novo nome do equipamento...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            <span id="erro_nome_edit" class="text-danger"></span>

            @component('components.input_text_email_num_date')
                @slot('label')
                    Token de Acesso:
                @endslot
                @slot('input_id')
                    token
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
                @slot('placeholder')
                    Inserir o token de acesso do equipamento...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            <span id="erro_token" class="text-danger"></span>

            @component('components.input_checkbox')
                @slot('checkbox_id')
                    not_associate
                @endslot
                @slot('label')
                    Não associar nenhum paciente
                @endslot
                @slot('checked')
                    {{-- Se é para começar ativado com checked se não não colocar nada --}}
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent

            <div id="associate_patient_div">
             {{-- select:start --}}
            @component('components.input_select')
                @slot('label')
                    Associar Paciente:
                @endslot
                @slot('select_id')
                    select_patient
                @endslot
                @slot('select_name')
                    select_patient
                @endslot
                @slot('options')
                    <option value="-1" disabled selected>Escolher paciente que ainda não tem equipamento...</option>
                    @foreach ($patients as $patient)
                        <option value="{{$patient->patient_id}}">{{$patient->patient_name}}</option>
                    @endforeach
                @endslot
                @slot('multiple')
                    {{-- Se multiselect preencher com multiple se não não colocar nada --}}
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                @endslot
            @endcomponent
            {{-- select:end --}}
            </div>

            @endslot


    @slot('buttons')
    {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
    {{-- button_primary:start --}}
    @component('components.button_primary')@slot('type')button @endslot
    @slot('extra')
    @endslot
    @slot('text')
    Guardar Alterações
    @endslot
    @slot('button_id')
	Editar_Equipamento
    @endslot
    @endcomponent
    {{-- button_primary:end --}}
</form>
@endslot
@endcomponent
{{-- modal:end --}}

<script>


    $("#Editar_Equipamento").click(function (event) {
        console.log("a enviar formulario")

        if ($("#not_associate").val() == "on") {
            $("#not_associate").val("1");
        }

        var form = $("#editar_equipamento");
        var url = form.attr('action') + "/" + $("#id").val();
        $("[id^=erro_]").html(""); //limpar todas as mensagens de erro

        $.ajax({
            type: "POST",
            url: url,
            dataType: 'json',
            data: form.serialize(), // serializes the form's elements.
            statusCode: {
                422: function (resposta) {
                    var lista_erros = JSON.parse(resposta.responseText);
                    for (nome_erro in lista_erros.errors) {
                        $("#erro_" + nome_erro).html(lista_erros.errors[nome_erro]);
                    }
                }
            },
            success: function (data) {
                // refresh page
                var url = "{{URL::to('/')}}" + data.redirect;
                $(location).attr('href', url);

                //var tr = $('#tabela_equipamentos tbody tr:eq(' + device.index() + ')');
                //tr.find('td:eq(1)').html($("#nome_edit").val());
                //table.rows(device).invalidate().draw();

                //$('#modal_edit_device').modal('toggle');

            }
        });
    });


</script>
