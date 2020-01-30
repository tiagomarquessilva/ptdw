{{-- modal:start--}}
@component('components.modal')
@slot('id')
modal_add_reminder
@endslot
@slot('aria_labelledby')
"Modal de adicionar lembrete"
@endslot
@slot('title')
Adicionar Lembrete
@endslot
@slot('body')
<form action="{{URL::to('/criar_lembrete')}}" method="post" id="add_remainder" novalidate>
    {{-- input_text:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Lembrete:
    @endslot
    @slot('input_id')
    reminder
    @endslot
    @slot('type')
    text
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    Inserir lembrete...
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_text:end --}}
    {{-- input_date:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Data a notificar:
    @endslot
    @slot('input_id')
    date_to_notify
    @endslot
    @slot('type')
    date
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    Inserir data...
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_date:end --}}
    {{-- input_time:start --}}
    @component('components.input_text_email_num_date')
    @slot('label')
    Hora de notificar:
    @endslot
    @slot('input_id')
    time_to_notify
    @endslot
    @slot('type')
    time
    @endslot
    @slot('required')
    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
    required
    @endslot
    @slot('placeholder')
    Inserir hora...
    @endslot
    @slot('value')
    @endslot
    @endcomponent
    {{-- input_time:end --}}
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
    Adicionar Lembrete
    @endslot
    @slot('button_id')
    button_add_reminder
    @endslot
    @endcomponent
</form>
@endslot
@endcomponent
{{-- modal:end --}}
