@extends('layout.layout')
@section('content')
    @push('scripts')
        <script src="{{URL::to('/js/vendor/echarts.min.js')}}"></script>
        <script src="{{URL::to('/js/es5/echart.options.min.js')}}"></script>
        <script src="{{URL::to('/js/es5/dashboard.v1.script.js')}}"></script>
    @endpush

    <div class="row">

    </div>

@stop
