<div class="row">
    <div class="col-sm-12">
        <div class="card">
            <div class="card-header  white-50  0-hidden pb-80">
                <div class="pt-4">
                    <div class="row">
                        <h4 class="col-md-4 text-black">{{$title}}</h4>
                    </div>
                </div>
            </div>
            <div class="card-body">
                <div class="ul-contact-list-body">
                    <div class="ul-contact-main-content">
                        <div class="ul-contact-left-side">
                            <div class="card">
                                <div class="card-body">
                                    <div class="ul-contact-list">
                                        <div class="contact-close-mobile-icon float-right mb-2">
                                            <i class="i-Close-Window text-15 font-weight-600"></i>
                                        </div>
                                        {{$left_card}}
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="ul-contact-content">
                            <div class="card">
                                <div class="card-body">
                                    <div class="float-left">
                                        <i class="nav-icon i-Align-Justify-All text-25 ul-contact-mobile-icon"></i>
                                    </div>
                                    <div class="tab-content ul-contact-list-table--label" id="nav-tabContent">
                                        <ul class="nav nav-tabs" id="{{$tabs_id}}" role="tablist">
                                            {{$list}}
                                        </ul>
                                        <!-- all-contact  -->
                                        <div class="tab-pane fade show active" id="list-home"
                                             role="tabpanel" aria-labelledby="list-home-list">

                                            <div id="report_page" class=" text-left ">
                                                <div id="chart_container">
                                                    {{$right_card}}
                                                </div>
                                            </div>
                                            <div class="float-right">
                                                @component('components.button_primary')
                                                    @slot('type')

                                                    @endslot
                                                    @slot('button_id')
                                                        export_id
                                                    @endslot
                                                    @slot('extra')

                                                    @endslot
                                                    @slot('text')
                                                        Exportar
                                                    @endslot
                                                @endcomponent
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
    </div>
</div>
