<?php
if (isset($_SESSION['scripts'])) {
    $_SESSION['scripts'] = array();
}

if (isset($_SESSION['css'])) {
    $_SESSION['css'] = array();
}
?>
<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>BedBuzz - {{$name}}</title>
    @push('css')
    <link href="https://fonts.googleapis.com/css?family=Nunito:300,400,400i,600,700,800,900" rel="stylesheet">
    <link href="{{URL::to('/fonts/iconsmind.woff')}}" rel="application/font-woff">
    <link id="gull-theme" href="{{URL::to('/css/lite-purple.css')}}" rel="stylesheet">
    <link href="{{URL::to('/css/perfect-scrollbar.css')}}" rel="stylesheet">
    <link rel="stylesheet" href="{{URL::to('/css/toastr.min.css')}}">
    <link rel="stylesheet" href="{{URL::to('/css/bootstrap-datepicker3.min.css')}}">
    <style type="text/css">
        @font-face {
            font-family: 'iconsmind';

            src: url('{{ URL::to('/fonts/iconsmind.eot?1cd6a624d6a7569e37128c287a443e7e')}}');
            src: url('{{ URL::to('/fonts/iconsmind.eot?1cd6a624d6a7569e37128c287a443e7e#iefix')}}') format("embedded-opentype"),
            url('{{ URL::to('/fonts/iconsmind.ttf?a925856d85799acc394635553311887a')}}') format("truetype"),
            url('{{ URL::to('/fonts/iconsmind.woff?5e5b709879b64c720a2c768a516ff0d3')}}') format("woff"),
            url('{{ URL::to('/fonts/iconsmind.svg?1f8fca36dc60dea28731a385dc3724ae#iconsmind')}}') format("svg");

            /*src:url('



            {{ URL::to('fonts/iconsmind.ttf?a925856d85799acc394635553311887a')}}') format("truetype"),
                url('



            {{ URL::to('fonts/iconsmind.woff?5e5b709879b64c720a2c768a516ff0d3')}}') format("woff");
                */
            font-weight: 400;
            font-style: normal
        }

            @font-face {
                font-family: 'iconsmind';
            }

        a.text-primary:hover {
            color: var(--primary) !important;
        }

        #pageTitle {
            margin: 0px;
        }

        .nav-item>.nav-item-hold {
            padding: 20px 0px !important;
        }

        .nav-icon {
            font-size: 30px !important;
            height: 30px !important;
            width: 30px !important;
        }

        .table-icon {
            font-size: 20px !important;
            height: 20px !important;
            width: 20px !important;
        }

        .card {
            margin: 6px;
        }

        .form-control:focus {
            box-shadow: 0 0 0 0.2rem rgba(239, 114, 21, .25);
            border-color: var(--primary);
        }

        .badge-secondary {
            color: black;
            background-color: initial;
            border: 1px solid black;
        }

        .invalid-input {
            border-color: #f44336;
        }

        .valid-input {
            border-color: #4caf50;
        }

        .invalid-input-message {
            width: 100%;
            margin-top: .25rem;
            font-size: 80%;
            color: #f44336;
        }

        .valid-input-message {
            width: 100%;
            margin-top: .25rem;
            font-size: 80%;
            color: #4caf50;
        }

        .sticky-notification {
            position: -webkit-sticky;
            /* Safari */
            position: sticky;
            bottom: 0;
        }

        .select2-container--default .select2-selection {
            outline: initial !important;
            background: #f8f9fa !important;
            border: 1px solid #ced4da !important;
            color: #47404f !important;

            display: block;
            width: 100%;
            height: calc(1.9695rem + 2px);
            font-size: .813rem;
            line-height: 1.5;
        }

        .select2-container--default.select2-container--focus .select2-selection {
            box-shadow: 0 0 0 0.2rem rgba(239, 114, 21, .25) !important;
            border-color: var(--primary) !important ;
        }

        .select2-dropdown {
            outline: initial !important;
            background: #f8f9fa !important;
            border: 1px solid #ced4da !important;
            color: #47404f !important;
        }

        .select2-container--default .select2-results__option--highlighted[aria-selected] {
            background-color: var(--primary);
        }
        
    </style>
    @endpush
    @stack('css')
    <script src="{{URL::to('/js/jquery-3.4.1.min.js')}}"></script>

</head>

<body class="text-left">
    <div class="app-admin-wrap layout-sidebar-large clearfix">
        <!-- header menu -->
        <div class="main-header">
            @include('layout.topbar')
        </div>
        <!-- header top menu end -->
        <!-- Sidebar -->
        <div class="side-content-wrap">
            @include('layout.sidebar')
        </div>
        <!-- End of Sidebar -->
        <!-- ============ Body content start ============= -->
        <div class="main-content-wrap sidenav-open d-flex flex-column">
            <div class="main-content">
                @component('components.breadcrumbs')
                @slot('name')
                {{$name ?? ''}}
                @endslot
                @slot('path')
                {{--<li><a href="/">Placeholder</a></li>
                    <li><a href="/styleguide">Placeholder</a></li>--}}
                @endslot
                @endcomponent
                @yield('content')
            </div>
            <!-- Footer Start -->
            @include('layout.footer')
            <!-- fotter end -->
        </div>
        <!-- ============ Body content End ============= -->
    </div>
    @prepend('scripts')
    <script src="{{URL::to('/js/common-bundle-script.js')}}"></script>
    <script src="{{URL::to('/js/script.js')}}"></script>
    <script src="{{URL::to('/js/sidebar.large.script.js')}}"></script>
    <script src="{{URL::to('/js/customizer.script.js')}}"></script>
    {{-- <script src="{{URL::to('/js/form.validation.script.js')}}"></script> --}}
    <script src="{{URL::to('/js/toastr.min.js')}}"></script>
    <script src="{{URL::to('/js/bootstrap-datepicker.min.js')}}"></script>
    <script>
        toastr.options = {
            "closeButton": true,
            "debug": false,
            "newestOnTop": true,
            "progressBar": true,
            "positionClass": "toast-top-right",
            "preventDuplicates": true,
            "onclick": null,
            "showDuration": "300",
            "hideDuration": "1000",
            "timeOut": "5000",
            "extendedTimeOut": "1000",
            "showEasing": "swing",
            "hideEasing": "linear",
            "showMethod": "fadeIn",
            "hideMethod": "fadeOut"
        }
    </script>
    @endprepend

    @stack('scripts')
</body>

</html>
