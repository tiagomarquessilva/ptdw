@push('css')
    <?php
    if (!isset($_SESSION)) {
        session_start();
    }

    if (!isset($_SESSION['css'])) {
        $_SESSION['css'] = array();
    }

    $term = "datatables";
    $css_tag = '<link rel="stylesheet" href="' . URL::to("/css/datatables.min.css") . '">';
    if (!in_array($term, $_SESSION['css'])) {
        array_push($_SESSION['css'], $term);
        echo $css_tag;
    }
    ?>
@endpush
<div class="row">
    <div class="col-md-12">
        <div class="card">
            <div class="card-header  gradient-purple-indigo  0-hidden pb-80">
                <div class="pt-4">
                    <div class="row">
                        <h4 class="col-md-4 text-white">{{$title}}</h4>
                    </div>
                </div>
            </div>
            <div class="card-body">
                <div class="ul-contact-list-body">
                    {{-- filters:start --}}
                    <div class="card">
                        <div class="card-body">
                            <div class="row">
                                <div class="col">
                                    <div style="display:inline-block;">
                                        @component('components.input_text_email_num_date')
                                            @slot('label')
                                                Pesquisar:
                                            @endslot
                                            @slot('input_id')
                                                {{$table_id}}_search
                                            @endslot
                                            @slot('type')
                                                text
                                            @endslot
                                            @slot('required')
                                                {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                                            @endslot
                                            @slot('placeholder')
                                                Procurar na Tabela...
                                            @endslot
                                            @slot('value')
                                            @endslot
                                        @endcomponent
                                    </div>
                                    {{$filters}}
                                </div>
                                <div class="col text-right align-self-center">
                                    {{$buttons}}
                                </div>
                            </div>
                        </div>
                    </div>
                    {{-- filters:end --}}
                    {{-- table:start --}}
                    <div class="ul-contact-content" style="width: 100%;">
                        <div class="card">
                            <div class="card-body">
                                <div class="ul-contact-list-table--label">
                                    <div class="tab-pane fade show active" role="tabpanel"
                                         aria-labelledby="list-home-list">
                                        <div class="table-responsive">
                                            <div class=" text-left ">
                                                <div class="dataTables_wrapper container-fluid dt-bootstrap4 no-footer">
                                                    <div class="row">
                                                        <div class="col-sm-12">
                                                            <table id="{{$table_id}}"
                                                                   class="display table table-borderless ul-contact-list-table dataTable no-footer"
                                                                   style="width: 100%;" role="grid"
                                                                   aria-describedby="{{$aria_describedby}}">
                                                                <thead>
                                                                {{$thead}}
                                                                </thead>
                                                                <tbody>
                                                                {{$tbody}}
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    {{-- table:end --}}
                </div>
            </div>
        </div>
    </div>
</div>
@push('scripts')
    <?php
    if (!isset($_SESSION)) {
        session_start();
    }

    if (!isset($_SESSION['scripts'])) {
        $_SESSION['scripts'] = array();
    }

    $term = "datatables";
    $script_tag = '<script src="' . URL::to("/js/datatables.min.js") . '"></script>';
    if (!in_array($term, $_SESSION['scripts'])) {
        array_push($_SESSION['scripts'], $term);
        echo $script_tag;
    }
    ?>
    <script>
        $(document).ready(function () {
            let table = $("#{{$table_id}}").DataTable({
                "info": false,
                "order": [[0, "asc"]],
                "paging": false,
                "scrollY": "50vh",
                "scrollX": true
            });
            $("#{{$table_id}}_search").on('keyup', function () {
                table.search(this.value).draw();
            });
        });
    </script>
@endpush
