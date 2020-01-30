{{-- modal:start--}}
@component('components.modal')
@slot('id')
modal_add_note
@endslot
@slot('aria_labelledby')
"Modal de adicionar nota"
@endslot
@slot('title')
Adicionar Nota
@endslot
@slot('body')
<form action="{{URL::to('/criar_nota')}}" method="post" id="add_note" novalidate>
    @component('components.input_text_email_num_date')
    @slot('label')
    Título:
    @endslot
    @slot('input_id')
    note_title
    @endslot
    @slot('type')
    text
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    Inserir título da nota...
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    <div class="form-group">
        <label for="note">Nota:</label>
        <textarea class="form-control" name="note" id="textarea_note" form="add_note" cols="30" rows="10" required
            placeholder="Inserir nota..."></textarea>
        <input name="paciente_id" id="paciente_id" value="" hidden/>
    </div>
    @endslot
    @slot('buttons')
    @component('components.button_primary')
    @slot('type')
    button
    @endslot
    @slot('extra')
    type="submit"
    @endslot
    @slot('text')
    Adicionar Nota
    @endslot
    @slot('button_id')
    button_add_note
    @endslot
    @endcomponent
</form>
@endslot
@endcomponent
{{-- modal:end --}}
@push("scripts")
<script>
    $(document).ready(function(){


    });
</script>
@endpush
