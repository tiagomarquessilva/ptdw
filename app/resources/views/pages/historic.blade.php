@extends('layout.layout')
@section('content')
    @component('components.graphics_history')
        @slot('title')
            Histórico
        @endslot
        @slot('left_card')
            <h5 class="card-title">FILTROS</h5>
            @component('components.input_switch')
                @slot('label')
                    Paciente
                @endslot
                @slot('switch_id')
                    switch_patient_id
                @endslot
                @slot('checked')
                    checked
                @endslot
                @slot('required')

                @endslot
            @endcomponent
            @component('components.input_switch')
                @slot('label')
                    Unidade de Saúde
                @endslot
                @slot('switch_id')
                    switch_us_id
                @endslot
                @slot('checked')

                @endslot
                @slot('required')

                @endslot
            @endcomponent
            @component('components.input_select')
                @slot('select_id')
                    select_patient_id
                @endslot
                @slot('select_name')
                    select_patient_id
                @endslot
                @slot('label')
                    Selecionar Paciente
                @endslot
                @slot('required')

                @endslot
                @slot('multiple')

                @endslot
                @slot('options')
                    <option value="all" selected>Todos</option>
                    @foreach($patients as $p)
                        <option value="{{$p->id}}">{{$p->nome}}</option>
                    @endforeach
                @endslot
            @endcomponent
            @component('components.input_select')
                @slot('select_id')
                    select_health_unit_id
                @endslot
                @slot('select_name')
                    select_health_unit_id
                @endslot
                @slot('label')
                    Selecionar Unidade de Saúde
                @endslot
                @slot('required')

                @endslot
                @slot('multiple')

                @endslot
                @slot('options')
                    @foreach($health_units as $h)
                        <option value="{{$h->id}}">{{$h->nome}}</option>
                    @endforeach
                @endslot
            @endcomponent
        @endslot
        @slot('tabs_id')
            tabs_graphics_id
        @endslot
        @slot('list')
            <li class="nav-item">
                <a class="nav-link active" id="bc_emg_tab" data-toggle="tab" href="#bc_emg_graphic" role="tab" aria-controls="bc_emg_Basic" aria-selected="true">
                    <i class="i-Pulse mr-1"></i>
                    Ambos
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="bc_tab" data-toggle="tab" href="#bc_graphic" role="tab" aria-controls="bc_Basic"
                   aria-selected="false">
                    <i class="i-Cardiovascular mr-1"></i>
                    BC
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" id="emg_tab" data-toggle="tab" href="#emg_graphic" role="tab" aria-controls="emg_Basic" aria-selected="false">
                    <i class="i-Elbow mr-1"></i>
                    EMG
                </a>
            </li>
        @endslot
        @slot('right_card')
            <canvas id="graphic" style="width:500px; height:300px"></canvas>
        @endslot
    @endcomponent
    @push('scripts')
        <script src="http://gull-html-laravel.ui-lib.com/assets/js/contact-list-table.js"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/moment.js') }}"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/chart.js') }}"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/Chart.min.js') }}"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/hammerjs.js') }}"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/chartjs-plugin-zoom.js') }}"></script>
        <script type="text/javascript" src="{{URL::to('/js/chartjs/utils.js') }}"></script>
        <script src="http://gull-html-laravel.ui-lib.com/assets/js/es5/dashboard.v1.script.js"></script>
        <script src="https://unpkg.com/jspdf@latest/dist/jspdf.min.js"></script>
        <script src="{{ URL::to('js/custom/graphics.js') }}"></script>
    @endpush
@endsection
