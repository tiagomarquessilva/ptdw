{{-- modal:start --}}
@component('components.modal')
@slot('id')
modal_add_device
@endslot
    @slot('aria_labelledby')
        Modal de Adicionar Equipamento
    @endslot
    @slot('title')
        Adicionar Equipamento
    @endslot
    @slot('body')
        <form id="inserir_equipamento" action="{{URL::to('/equipamento')}}" method="POST" novalidate>
            @csrf
            @component('components.input_text_email_num_date')
                @slot('label')
                    Nome do Equipamento:
                @endslot
                @slot('input_id')
                    nome
                @endslot
                @slot('type')
                    text
                @endslot
                @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                @endslot
                @slot('placeholder')
                    Inserir nome do equipamento...
                @endslot
                @slot('value')
                @endslot
            @endcomponent
            <span id="erro_nome" class="text-danger"></span>
            @endslot





            @slot('buttons')
                {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
                {{-- button_primary:start --}}
                @component('components.button_primary')@slot('type')button @endslot
                @slot('extra')
                @endslot
                @slot('text')
                    Adicionar Equipamento
                @endslot
                @slot('button_id')
                    Adicionar_Equipamento
                @endslot
                @endcomponent
                {{-- button_primary:end --}}

        </form>
    @endslot
@endcomponent
{{-- modal:end --}}

<script>
    $("#Adicionar_Equipamento").click(function (event) {
        console.log("a enviar formulario");

        var form = $("#inserir_equipamento");
        var url = form.attr('action');
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
                /*
                var equipamento = data.equipamento;
                var t = $('#tabela_equipamentos').DataTable();
                t.row.add([
                    equipamento.id,
                    equipamento.nome,
                    equipamento.access_token,
                    equipamento.esta_associado,
                ]).draw(false);

                console.table(data);
                $('#modal_add_device').modal('hide');
                */
            }
        });
    });


</script>
