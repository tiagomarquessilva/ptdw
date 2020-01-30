$(document).ready(function () {
    let line_chart_data, ctx = document.getElementById('graphic').getContext('2d')
        , chart, label_axis, blue_color = 'rgba(44, 130, 201, 1)', id = 'bc_emg_tab';

    function get_diff_time(start_date, end_date, unit_time) {
        return moment(end_date).diff(moment(start_date), unit_time);
    }

    function get_unit_time(start_date, end_date) {
        var diff = get_diff_time(start_date, end_date, 'seconds');

        if (diff > 30) {
            diff = get_diff_time(start_date, end_date, 'minutes');

            if (diff > 30) {
                diff = get_diff_time(start_date, end_date, 'hours');

                if (diff > 30) {
                    diff = get_diff_time(start_date, end_date, 'days');

                    if (diff > 30) {
                        diff = get_diff_time(start_date, end_date, 'weeks');

                        if (diff > 30) {
                            diff = get_diff_time(start_date, end_date, 'months');

                            if (diff > 20) {
                                diff = get_diff_time(start_date, end_date, 'years');

                                if (diff > 30) return {
                                    'unit': 'year',
                                    'label': 'anos'
                                };
                                return {
                                    'unit': 'quarter',
                                    'label': 'trimestres'
                                };
                            }
                            return {
                                'unit': 'month',
                                'label': 'meses'
                            };
                        }
                        return {
                            'unit': 'week',
                            'label': 'semanas'
                        };
                    }
                    return {
                        'unit': 'day',
                        'label': 'dias'
                    };
                }
                return {
                    'unit': 'hour',
                    'label': 'horas'
                };
            }
            return {
                'unit': 'minute',
                'label': 'minutos'
            };
        }
        return {
            'unit': 'second',
            'label': 'segundos'
        };
    }

    function set_time_graphic_one_axis(emg, bc, equipments, time_unit) {
        chart.destroy();
        if (id === 'bc_tab') {
            line_chart_data = {
                datasets: [{
                    label: 'Batimento Cardíaco',
                    data: bc,
                    backgroundColor: window.chartColors.orange,
                    borderColor: window.chartColors.orange,
                    fill: false,
                    borderWidth: 3,
                }],
            };
            label_axis = 'Batimento Cardíaco (bpm)';
        } else {
            line_chart_data = {
                datasets: [{
                    label: 'Eletromiografia',
                    data: emg,
                    backgroundColor: blue_color,
                    borderColor: blue_color,
                    fill: false,
                    borderWidth: 3,
                }],
            };
            label_axis = 'Eletromiografia (ms)';
        }
        chart = new Chart(ctx, {
            type: 'line',
            data: line_chart_data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                        type: 'time',
                        time: {
                            unit: time_unit.unit,
                            minUnit: 'second',
                            displayFormats: {
                                second: 'H:mm:ss',
                                minute: 'H:mm',
                                hour: 'H',
                                quarter: 'MMM YYYY'
                            },

                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Tempo (' + time_unit.label + ')'
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: label_axis
                        },
                    }]
                },
                tooltips: {
                    intersect: false,
                    mode: 'index',
                    callbacks: {
                        title: function (tooltipItem, data) {
                            return tooltipItem[0].xLabel + "\nEquipamento: " + equipments[tooltipItem[0].index];
                        },
                    }
                },
                // Container for pan options
                pan: {
                    // Boolean to enable panning
                    enabled: true,

                    // Panning directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow panning in the y direction
                    mode: 'x',

                    speed: 1
                },

                // Container for zoom options
                zoom: {
                    // Boolean to enable zooming
                    enabled: true,
                    // Zooming directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow zooming in the y direction
                    mode: 'x',
                }
            }
        });
        chart.update();
    }

    function set_time_graphic_double_axis(emg, bc, equipments, time_unit) {
        chart.destroy();
        chart = new Chart(ctx, {
            type: 'line',
            data: {
                datasets: [{
                    label: 'Batimento Cardíaco',
                    data: bc,
                    backgroundColor: window.chartColors.orange,
                    borderColor: window.chartColors.orange,
                    fill: false,
                    borderWidth: 3,
                }, {
                    label: 'Eletromiografia',
                    data: emg,
                    backgroundColor: blue_color,
                    borderColor: blue_color,
                    fill: false,
                    borderWidth: 3,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                            type: 'time',
                        time: {
                            unit: time_unit.unit,
                            minUnit: 'second',
                            displayFormats: {
                                second: 'H:mm:ss',
                                minute: 'H:mm',
                                hour: 'H',
                                quarter: 'MMM YYYY'
                            },

                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Tempo (' + time_unit.label + ')'
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Valores',
                        },
                        position: 'left',
                        id: 'y-axis-1'
                    }, {
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Valores',
                        },
                        position: 'right',
                        id: 'y-axis-2'
                    }]
                },
                tooltips: {
                    intersect: false,
                    mode: 'index',
                    callbacks: {
                        title: function (tooltipItem, data) {
                            return tooltipItem[0].xLabel + "\nEquipamento: " + equipments[tooltipItem[0].index];
                        },
                    }
                },
                // Container for pan options
                pan: {
                    // Boolean to enable panning
                    enabled: true,

                    // Panning directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow panning in the y direction
                    mode: 'x',

                    speed: 1
                },

                // Container for zoom options
                zoom: {
                    // Boolean to enable zooming
                    enabled: true,
                    // Zooming directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow zooming in the y direction
                    mode: 'x',
                }
            }
        });
        chart.update();
    }

    // gera o gráfico com um eixo dos y's
    function set_graphic_one_yaxis(id, names, equipments, emg, bc) {
        chart.destroy();
        if (id === 'bc_tab') {
            line_chart_data = {
                labels: names,
                datasets: [{
                    label: 'Batimento Cardíaco',
                    data: bc,
                    backgroundColor: window.chartColors.orange,
                    borderColor: window.chartColors.orange,
                    fill: false,
                    borderWidth: 3,
                }]
            };
            label_axis = '(bpm)';
        } else {
            line_chart_data = {
                labels: names,
                datasets: [{
                    label: 'Eletromiografia',
                    data: emg,
                    backgroundColor: blue_color,
                    borderColor: blue_color,
                    fill: false,
                    borderWidth: 3,
                }]
            };
            label_axis = '(ms)';
        }
        chart = new Chart(ctx, {
            type: 'line',
            data: line_chart_data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                        scaleLabel: {
                            display: true,
                            labelString: 'Pacientes'
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Média ' + label_axis,
                        },
                    }]
                },
                tooltips: {
                    intersect: false,
                    mode: 'index',
                    callbacks: {
                        title: function (tooltipItem, data) {
                            let index = tooltipItem[0].index;
                            return data.labels[index] + "\nEquipamentos: " + equipments[index];
                        },
                    }
                },
                // Container for pan options
                pan: {
                    // Boolean to enable panning
                    enabled: true,

                    // Panning directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow panning in the y direction
                    mode: 'x',

                    speed: 1
                },

                // Container for zoom options
                zoom: {
                    // Boolean to enable zooming
                    enabled: true,
                    // Zooming directions. Remove the appropriate direction to disable
                    // Eg. 'y' would only allow zooming in the y direction
                    mode: 'x',
                }
            }
        });
        chart.update();
    }

    // gera o gráfico com dois eixos dos y's
    function set_graphic_double_yaxis(names, equipments, emg, bc) {
        if (chart) chart.destroy();
        line_chart_data = {
            labels: names,
            datasets: [{
                label: 'Batimento Cardíaco',
                data: bc,
                backgroundColor: window.chartColors.orange,
                borderColor: window.chartColors.orange,
                fill: false,
                borderWidth: 3,
            }, {
                label: 'Eletromiografia',
                data: emg,
                backgroundColor: blue_color,
                borderColor: blue_color,
                fill: false,
                borderWidth: 3,
            }]
        };
        chart = new Chart(ctx, {
            type: 'line',
            data: line_chart_data,
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    xAxes: [{
                        scaleLabel: {
                            display: true,
                            labelString: 'Pacientes'
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Média',
                        },
                        position: 'left',
                        id: 'y-axis-1'
                    }, {
                        ticks: {
                            beginAtZero: true
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Média',
                        },
                        position: 'right',
                        id: 'y-axis-2'
                    }],
                },
                tooltips: {
                    intersect: false,
                    mode: 'index',
                    callbacks: {
                        title: function (tooltipItem, data) {
                            let index = tooltipItem[0].index;
                            return data.labels[index] + "\nEquipamentos: " + equipments[index];
                        },
                    }
                },
                pan: {
                    enabled: true,

                    mode: 'x',

                    speed: 1
                },
                zoom: {
                    enabled: true,
                    mode: 'x',
                }
            },
        });
        if (chart) chart.update();
    }

    // gera o gráfico por omissão (dois eixos y's)
    function set_default_graphic() {
        if ($("#switch_patient_id").is(':checked')) {
            var select_patient_name = $("#select_patient_id");
            if (select_patient_name[0].selectedIndex === 0)
                $.ajax({
                    type: "GET",
                    dataType: 'json',
                    url: window.location.href + "/patients",
                    success: function (data) {
                        if (data.success) set_graphic_double_yaxis(
                            data.historic.names, data.historic.equipments, data.historic.emg, data.historic.bc
                        );
                        else alert("Ocorreu um erro. Tente novamente.");
                    },
                    error: function (e) {
                        alert(e);
                    }
                });
            else
                $.ajax({
                    type: "GET",
                    dataType: 'json',
                    url: window.location.href + "/patient/" + select_patient_name.val(),
                    success: function (data) {
                        if (data.success) {
                            if (data.historic.bc.length > 0) {
                                var start_date = moment(data.historic.bc[0].t),
                                    end_date = moment(data.historic.bc[data.historic.bc.length - 1].t);
                                set_time_graphic_double_axis(
                                    data.historic.emg, data.historic.bc, data.historic.equipments, get_unit_time(start_date, end_date)
                                );
                            } else
                                set_time_graphic_double_axis(
                                    null, null, null,{'unit': 'day', 'label': 'dias'}
                                );
                        } else alert("Ocorreu um erro. Tente novamente.");
                    },
                    error: function (e) {
                        alert(e);
                    }
                });
        } else
            $.ajax({
                type: "GET",
                dataType: 'json',
                url: window.location.href + "/health_unit/" + $("#select_health_unit_id").val(),
                success: function (data) {
                    if (data.success) set_graphic_double_yaxis(
                        data.historic.names, data.historic.equipments, data.historic.emg, data.historic.bc
                    );
                    else alert("Ocorreu um erro. Tente novamente.");
                },
                error: function (e) {
                    alert(e);
                }
            });
    }

    function get_data_graphic_one_yaxis(id) {
        if ($("#switch_patient_id").is(':checked')) {
            var select_patient_name = $("#select_patient_id");
            if (select_patient_name[0].selectedIndex === 0)
                $.ajax({
                    type: "GET",
                    dataType: 'json',
                    url: window.location.href + "/patients",
                    success: function (data) {
                        if (data.success) set_graphic_one_yaxis(
                            id, data.historic.names, data.historic.equipments, data.historic.emg, data.historic.bc
                        );
                        else alert("Ocorreu um erro. Tente novamente.");
                    },
                    error: function (e) {
                        alert(e);
                    }
                });
            else
                $.ajax({
                    type: "GET",
                    dataType: 'json',
                    url: window.location.href + "/patient/" + select_patient_name.val(),
                    success: function (data) {
                        if (data.success) {
                            if (data.historic.bc.length > 0) {
                                var start_date = moment(data.historic.bc[0].t),
                                    end_date = moment(data.historic.bc[data.historic.bc.length - 1].t);
                                set_time_graphic_one_axis(
                                    data.historic.emg, data.historic.bc, data.historic.equipments, get_unit_time(start_date, end_date)
                                );
                            } else
                                set_time_graphic_one_axis(
                                    null, null, null, {'unit': 'day', 'label': 'dias'}
                                );
                        } else alert("Ocorreu um erro. Tente novamente.");
                    },
                    error: function (e) {
                        alert(e);
                    }
                });
        } else {
            $.ajax({
                type: "GET",
                dataType: 'json',
                url: window.location.href + "/health_unit/" + $("#select_health_unit_id").val(),
                success: function (data) {
                    if (data.success) set_graphic_one_yaxis(
                        id, data.historic.names, data.historic.equipments, data.historic.emg, data.historic.bc
                    );
                    else alert("Ocorreu um erro. Tente novamente.");
                },
                error: function (e) {
                    alert(e);
                }
            });
        }
    }

    function check_tab_actived() {
        if (id === 'bc_emg_tab') {
            set_default_graphic();
        } else get_data_graphic_one_yaxis(id);
    }


    // INICIO
    $('#select_health_unit_id').attr('disabled', 'disabled');

    set_default_graphic();

    // muda o tipo de dados a mostrar no gráfico
    $('#tabs_graphics_id a').click(function (e) {
        id = $(this).attr('id');
        check_tab_actived();
    });

    // clica no switch das Unidades de Saúde
    $("#switch_us_id").on('change', function () {
        if ($(this).is(':checked')) {
            $('#select_health_unit_id').attr('disabled', false);
            $('#select_patient_id').attr('disabled', 'disabled');
            $("#switch_patient_id").trigger("click");
            check_tab_actived();
        } else {
            $('#select_health_unit_id').attr('disabled', 'disabled');
            $('#select_patient_id').attr('disabled', false);
            $("#switch_patient_id").trigger("click");
            check_tab_actived();
        }
    });

    // clica no switch dos Pacientes
    $("#switch_patient_id").on('change', function () {
        if ($(this).is(':checked')) {
            $('#select_health_unit_id').attr('disabled', 'disabled');
            $('#select_patient_id').attr('disabled', false);
            $("#switch_us_id").trigger("click");
            check_tab_actived();
        } else {
            $('#select_health_unit_id').attr('disabled', false);
            $('#select_patient_id').attr('disabled', 'disabled');
            $("#switch_us_id").trigger("click");
            check_tab_actived();
        }
    });

    // escolhe uma opção das Unidades de Saúde
    $("#select_health_unit_id").on('change', function () {
        check_tab_actived();
    });

    $("#select_patient_id").on('change', function () {
        check_tab_actived();
    });

    // quando clica no botão para exportar para PDF
    $('#export_id').click(function (event) {
        // get size of report page
        var reportPageHeight = $('#chart_container').innerHeight();
        var reportPageWidth = $('#chart_container').innerWidth();
        // create a new canvas object that we will populate with all other canvas objects
        var pdfCanvas = $('<canvas />').attr({
            id: "canvaspdf",
            width: reportPageWidth,
            height: reportPageHeight,
        });
        // keep track canvas position
        var pdfctx = $(pdfCanvas)[0].getContext('2d');
        pdfctx.fillStyle = '#ffffff';
        pdfctx.fillRect(0, 0, reportPageWidth, reportPageHeight); //fin
        var pdfctxX = 0;
        var pdfctxY = 0;
        var buffer = 100;
        // for each chart.js chart
        $("canvas").each(function (index) {
            // get the chart height/width
            var canvasHeight = $(this).innerHeight();
            var canvasWidth = $(this).innerWidth();
            // draw the chart into the new canvas
            pdfctx.drawImage($(this)[0], pdfctxX, pdfctxY, canvasWidth, canvasHeight);
            pdfctxX += canvasWidth + buffer;
            // our report page is in a grid pattern so replicate that in the new canvas
            if (index % 2 === 1) {
                pdfctxX = 0;
                pdfctxY += canvasHeight + buffer;
            }
        });
        // create new pdf and add our new canvas as an image
        var pdf = new jsPDF('l', 'pt', [reportPageWidth, reportPageHeight]);
        pdf.addImage($(pdfCanvas)[0], 'PNG', 0, 0);
        // download the pdf
        pdf.save('bedbuzz_historico.pdf');
    });
});
