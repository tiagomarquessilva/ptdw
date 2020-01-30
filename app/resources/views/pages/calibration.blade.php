@extends('layout.layout')
@section('content')

<form id="inserir_calibracao" action="{{URL::to('/calibracao')}}" method="post" novalidate>
    @csrf
    <input type="hidden" name="paciente_id" value="{{$paciente_id}}">
    <input type="hidden" name="equipamento_id" value="{{$equipamento_id}} ">
    <div class="row">
        <!--
        <div class="col-4">
            {{-- card:start --}}
            @component('components.card')
            @slot('title')
            Associar
            @endslot
            @slot('body')
                        <div class="row align-items-center">
                            <div class="col-sm-2">
                                <i class="nav-icon i-Background"
                                   style="font-size: 40px !important; height: 40px !important; width: 40px !important;"></i>
                            </div>
                            <div class="col-sm-10">
                                {{-- select:start --}}
                                @component('components.input_select')
                                    @slot('label')
                                        Equipamento:
                                    @endslot
                                    @slot('select_id')
                                        select_device
                                    @endslot
                                    @slot('select_name')
                                        select_device
                                    @endslot
                                    @slot('options')
                                        <option value="AL">Alabama</option>
                                        <option value="WY">Wyoming</option>
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
                        </div>
                        <div class="row align-items-center">
                            <div class="col-sm-2">
                                <i class="nav-icon i-Background"
                                   style="font-size: 40px !important; height: 40px !important; width: 40px !important;"></i>
                            </div>
                            <div class="col-sm-10">
                                {{-- select:start --}}
                        @component('components.input_select')
                            @slot('label')
                                Paciente:
                            @endslot
                            @slot('select_id')
                                select_paciente
                            @endslot
                            @slot('select_name')
                                select_paciente
                            @endslot
                            @slot('options')
                                <option value="AL">Alabama</option>
                                <option value="WY">Wyoming</option>
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
                        </div>
                    @endslot
                @endcomponent
                {{-- card:end --}}
            </div>
            <div class="col">
                @component('components.card')
                    @slot('title')
                        Calibrar
                    @endslot
                    @slot('body')
                        <div class="row">
                            <div class="col">
                                @component('components.input_text_email_num_date')
                                    @slot('label')
                                        Batimento cardíaco mínimo:
                                    @endslot
                                    @slot('input_id')
                                        bpm_min
                                    @endslot
                                    @slot('type')
                                        number
                                    @endslot
                                    @slot('required')
                                        {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                        required
                                    @endslot
                                    @slot('placeholder')
                                        Inserir valor mínimo do batimento cardíaco...
                                    @endslot
                                    @slot('value')
                                    @endslot
                                @endcomponent
                                @component('components.input_text_email_num_date')
                                    @slot('label')
                                        Batimento cardíaco máximo:
                                    @endslot
                                    @slot('input_id')
                                        bpm_max
                                    @endslot
                                    @slot('type')
                                        number
                                    @endslot
                                    @slot('required')
                                        {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                        required
                                    @endslot
                                    @slot('placeholder')
                                        Inserir valor máximo do batimento cardíaco...
                                    @endslot
                                    @slot('value')
                                    @endslot
                                @endcomponent
                            </div>
                            <div class="col">
                                @component('components.input_text_email_num_date')
                                    @slot('label')
                                        EMG mínimo:
                                    @endslot
                                    @slot('input_id')
                                        emg_min
                                    @endslot
                                    @slot('type')
                                        number
                                    @endslot
                                    @slot('required')
                                        {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                        required
                                    @endslot
                                    @slot('placeholder')
                                        Inserir valor mínimo do EMG...
                                    @endslot
                                    @slot('value')
                                    @endslot
                                @endcomponent
                                @component('components.input_text_email_num_date')
                                    @slot('label')
                                        EMG máximo:
                                    @endslot
                                    @slot('input_id')
                                        emg_max
                                    @endslot
                                    @slot('type')
                                        number
                                    @endslot
                                    @slot('required')
                                        {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                        required
                                    @endslot
                                    @slot('placeholder')
                                        Inserir valor máximo do EMG...
                                    @endslot
                                    @slot('value')
                                    @endslot
                                @endcomponent
                            </div>
                        </div>
                        <div class="row">
                            <div class="col align-self-start">
                                @component('components.button_secondary')
                                    @slot('extra')
                                        data-toggle="modal" data-target="#modal_past_confs"
                                    @endslot
                                    @slot('type')
                                        button
                                    @endslot
                                    @slot('text')
                                        Configurações Passadas
                                    @endslot
                                    @slot('button_id')
                                        button_past_confs
                                    @endslot
                                @endcomponent
                            </div>
                            <div class="col align-self-end text-right">
                                {{-- button_primary:start --}}
                                @component('components.button_primary')
                                    @slot('type')
                                        submit
                                    @endslot
                                    @slot('extra')
                                    @endslot
                                    @slot('text')
                                        Calibrar Equipamento
                                    @endslot
                                    @slot('button_id')
                                        button_submit_confs
                                    @endslot
                                @endcomponent
                                {{-- button_primary:end --}}
                            </div>
                        </div>
                    @endslot
                @endcomponent
            </div>
        </div>
        -->
        <div class="col">
            @component('components.card')
            @slot('title')
            Calibrar
            @endslot
            @slot('body')
            <div class="row">
                <div class="col">
                    @component('components.input_text_email_num_date')
                    @slot('label')
                    Batimento cardíaco mínimo:
                    @endslot
                    @slot('input_id')
                    bpm_min
                    @endslot
                    @slot('type')
                    number
                    @endslot
                    @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                    @endslot
                    @slot('placeholder')
                    Inserir valor mínimo do batimento cardíaco...
                    @endslot
                    @slot('value')
                    @endslot
                    @endcomponent
                    <span id="erro_bpm_min" class="text-danger"></span>
                    @component('components.input_text_email_num_date')
                    @slot('label')
                    Batimento cardíaco máximo:
                    @endslot
                    @slot('input_id')
                    bpm_max
                    @endslot
                    @slot('type')
                    number
                    @endslot
                    @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                    @endslot
                    @slot('placeholder')
                    Inserir valor máximo do batimento cardíaco...
                    @endslot
                    @slot('value')
                    @endslot
                    @endcomponent
                    <span id="erro_bpm_max" class="text-danger"></span>
                </div>
                <div class="col">
                    @component('components.input_text_email_num_date')
                    @slot('label')
                    EMG mínimo:
                    @endslot
                    @slot('input_id')
                    emg_min
                    @endslot
                    @slot('type')
                    number
                    @endslot
                    @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                    @endslot
                    @slot('placeholder')
                    Inserir valor mínimo do EMG...
                    @endslot
                    @slot('value')
                    @endslot
                    @endcomponent
                    <span id="erro_emg_min" class="text-danger"></span>
                    @component('components.input_text_email_num_date')
                    @slot('label')
                    EMG máximo:
                    @endslot
                    @slot('input_id')
                    emg_max
                    @endslot
                    @slot('type')
                    number
                    @endslot
                    @slot('required')
                    {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                    required
                    @endslot
                    @slot('placeholder')
                    Inserir valor máximo do EMG...
                    @endslot
                    @slot('value')
                    @endslot
                    @endcomponent
                    <span id="erro_emg_max" class="text-danger"></span>
                </div>
            </div>
            <div class="row">
                <div class="col align-self-start">
                    @component('components.button_secondary')
                    @slot('type')
                    button
                    @endslot
                    @slot('extra')
                    data-toggle="modal" data-target="#modal_past_confs"
                    @endslot
                    @slot('text')
                    Configurações Passadas
                    @endslot
                    @slot('button_id')
                    button_past_confs
                    @endslot
                    @endcomponent
                </div>
                <div class="col align-self-end text-right">
                    {{-- button_primary:start --}}
                    @component('components.button_primary')@slot('type')button @endslot
                    @slot('extra')

                    @endslot
                    @slot('text')
                    Calibrar Equipamento
                    @endslot
                    @slot('button_id')
                    button_submit_confs
                    @endslot
                    @endcomponent
                    {{-- button_primary:end --}}
                </div>
            </div>
            @endslot
            @endcomponent
        </div>
    </div>
</form>
<div class="row">
    <div class="col">
        @component('components.card')
        @slot('title')
        Equipamento
        @endslot
        @slot('body')
        <div class="row">
            <div class="col-2">
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        BPM Atual
                        @endslot
                        @slot('body')
                        <h1  id="atual_bpm">XXX</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        BPM Máximo
                        @endslot
                        @slot('body')
                        <h1 id="max_bpm">50</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        BPM Mínimo
                        @endslot
                        @slot('body')
                        <h1 id="min_bpm">50</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
            </div>
            <div class="col-8">
                <canvas id="LineChart"
                    style="display: block; width: 529px; height: 264px;"></canvas>
            </div>
            <div class="col-2">
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        EMG Atual
                        @endslot
                        @slot('body')
                        <h1 id="atual_emg">XXX</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        EMG Máximo
                        @endslot
                        @slot('body')
                        <h1 id="max_emg">50</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
                <div class="row">
                    <div class="col">
                        @component('components.card')
                        @slot('title')
                        EMG Mínimo
                        @endslot
                        @slot('body')
                        <h1 id="min_emg">50</h1>
                        @endslot
                        @endcomponent
                    </div>
                </div>
            </div>
        </div>
        @endslot
        @endcomponent
    </div>
</div>
@include('modals.modal_patient_past_confs')

@push('css')
    <link rel="stylesheet" href="{{URL::to('/js/chartjs/Chart.min.css') }}">
@endpush

@push('scripts')
    <script type="text/javascript" src="{{URL::to('/js/chartjs/moment.js') }}"></script>
    <script type="text/javascript" src="{{URL::to('/js/chartjs/Chart.min.js') }}"></script>
    <script type="text/javascript" src="{{URL::to('/js/chartjs/hammerjs.js') }}"></script>
    <script type="text/javascript" src="{{URL::to('/js/chartjs/chartjs-plugin-zoom.js') }}"></script>
    <script type="text/javascript" src="{{URL::to('/js/chartjs/chartjs-plugin-streaming.min.js') }}"></script>

<script>
    var chart;
    var config;
    var id_registo = 0;
    var equipamento_id = {{$equipamento_id}} ;
    var paciente_id = {{$paciente_id}} ;
    var tempo = moment().format();


$(document).ready( function () {
    backgroundColors =  [
        'rgba(255, 99, 132, 0.2)',
        'rgba(54, 162, 235, 0.2)',
        'rgba(255, 206, 86, 0.2)',
        'rgba(75, 192, 192, 0.2)',
        'rgba(153, 102, 255, 0.2)',
        'rgba(255, 159, 64, 0.2)'
    ];
    borderColors = [
        'rgba(255, 99, 132, 1)',
        'rgba(54, 162, 235, 1)',
        'rgba(255, 206, 86, 1)',
        'rgba(75, 192, 192, 1)',
        'rgba(153, 102, 255, 1)',
        'rgba(255, 159, 64, 1)'
    ];

    function onRefresh(chart) {

        //v1 = Math.floor(Math.random() * 101);
        //v2 = Math.floor(Math.random() * 10) /10

        //chart.data.labels.push(Date.now());
        //chart.data.datasets[0].data.push(v1);
        //chart.data.datasets[1].data.push(v2);


        $.ajax({
            type: "GET",
            url: "{{URL::to('/calibracao/' .$equipamento_id. '/getUltimoRegisto')}}",
            dataType: 'json',
            data: {
                "_token": "{{csrf_token()}}",
                "id_registo": id_registo,
                "tempo" : tempo,
            },
            success: function(data){
                //console.table(data);
                if (data.length != 0 ){
                    console.table(data);
                    $.each(data, function (key, value) {
                        console.log(data[key]);
                        var bpm = data[key]["bc"];
                        var emg = data[key]["emg"];
                        chart.data.labels.push(data[key]["data_registo"]);
                        chart.data.datasets[0].data.push(bpm);
                        chart.data.datasets[1].data.push(emg);

                        config.options.scales["yAxes"][0].ticks.max > bpm? null : config.options.scales["yAxes"][0].ticks.max = bpm;
                        config.options.scales["yAxes"][1].ticks.max > emg? null : config.options.scales["yAxes"][1].ticks.max = emg;

                        $("#max_bpm").text() > bpm ? null :  $("#max_bpm").text(bpm);
                        $("#min_bpm").text() < bpm ? null :  $("#min_bpm").text(bpm);
                        $("#atual_bpm").text(bpm);

                        $("#max_emg").text() > emg ? null :  $("#max_emg").text(emg);
                        $("#min_emg").text() < emg ? null :  $("#min_emg").text(emg);
                        $("#atual_emg").text(emg);
                    });

                    id_registo = data[data.length-1]["id"];
                    console.log("novo id : " +  id_registo);
                }
                else{
                    console.log("sem dados novos");
                }
            }
        });

    }

    var canvas = document.getElementById('LineChart').getContext('2d');

    config = {
        type: 'line',
        data: {
            datasets: [{
                label: 'BPM',
                yAxisID: 'A',
                data: [],
                backgroundColor: backgroundColors[0],
                borderColor : borderColors[0]
            },
                {
                    label: 'EMG',
                    yAxisID: 'B',
                    data: [],
                    backgroundColor: backgroundColors[1],
                    borderColor : borderColors[1]
                }]
        },
        options: {
            responsive : true,
            scales: {
                xAxes: [{
                    type: 'realtime',
                    realtime: {
                        duration: 20000,
                        refresh: 1000,
                        delay: 2000,
                        onRefresh: onRefresh
                    }
                }],
                yAxes: [{
                    id: 'A',
                    type: 'linear',
                    display: true,
                    scaleLabel: {
                        display: true,
                        labelString: 'BPM'
                    },
                    position: 'left',
                    ticks: {
                        max: 100,
                        min: 0
                    }
                },
                    {
                        id: 'B',
                        type: 'linear',
                        display: true,
                        scaleLabel: {
                            display: true,
                            labelString: 'EMG'
                        },
                        position: 'right',
                        ticks: {
                            max: 100,
                            min: 0
                        }
                    }

                ]
            },
            tooltips: {
                mode: 'nearest',
                intersect: false
            },
            hover: {
                mode: 'nearest',
                intersect: false
            },
            pan: {
                enabled: true,
                mode: 'x',
                rangeMax: {
                    x: 8000
                },
                rangeMin: {
                    x: 0
                }
            },
            zoom: {
                enabled: true,
                mode: 'x',
                rangeMax: {
                    x: 20000
                },
                rangeMin: {
                    x: 1000
                }
            }
        }
    };



    chart = new Chart(canvas, config);

}); //end of document.ready


    //submeter uma nova configuração
    $( "#button_submit_confs" ).click(function(event) {
        console.log("a enviar formulario")

        var form = $("#inserir_calibracao");
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
                    for (nome_erro in lista_erros.errors){
                        $("#erro_"+nome_erro).html(lista_erros.errors[nome_erro]);
                    }
                }
            },
            success: function(data)
            {
                // redirect page
                var url = "{{URL::to('/')}}" + data.redirect;
                $(location).attr('href', url);

            }
        });
    });

    var table;
    //abrir modal configurações passadas
    $('#modal_past_confs').on('shown.bs.modal', function () {
        $.ajax({
            type: "GET",
            url: "{{URL::to('/historicoConfiguracoes')}}" + "/"+ paciente_id,
            dataType: 'json',

            success: function(data)
            {
                console.table(data);
                //$("#past_confs_table tbody").html("");
                table = $('#past_confs_table').DataTable();

                table.clear().draw();
                table.order([ 0, 'desc' ]);

                var button = '<button type="button" class="btn btn-raised btn-raised-primary m-1" data-select style="white-space: normal;">Usar Configuração</button>';

                $.each(data,function (index,value) {
                    table.row.add( [
                        value.data_registo,
                        value.bpm_max,
                        value.bpm_min,
                        value.emg_max,
                        value.emg_min,
                        value.equipamento_id,
                        '<div class="col align-self-center align-middle">' + button + '</div>',
                    ] ).draw( false );
                });

                //selecionar config passada
                $('#past_confs_table [data-select]').on( 'click', function () {
                    config = table.row(this.closest("tr"));
                    let config_data = config.data();
                    $("#bpm_max").val(config_data[1]);
                    $("#bpm_min").val(config_data[2]);
                    $("#emg_max").val(config_data[3]);
                    $("#emg_min").val(config_data[4]);
                    $('#modal_past_confs').modal('toggle');
                });

            }
        }); //end of ajax

    });



</script>
@endpush
@endsection
