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
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <!-- CSRF Token -->
    <meta name="csrf-token" content="M1RgFnbtAaCSSz9dYg1TP2ksWKeLmztWVA5fo2fp">
    <title>BedBuzz - {{Route::current()->getName()}}</title>
    @push('css')
        <link href="https://fonts.googleapis.com/css?family=Nunito:300,400,400i,600,700,800,900" rel="stylesheet">
        <link href="{{URL::to('/fonts/iconsmind.woff')}}" rel="application/font-woff">
        <link id="gull-theme" href="{{URL::to('/css/lite-purple.css')}}" rel="stylesheet">
        <link href="{{URL::to('/css/perfect-scrollbar.css')}}" rel="stylesheet">
        <link rel="stylesheet" href="{{URL::to('/css/toastr.min.css')}}">
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
                src:
            }

            a.text-primary:hover {
                color: var(--primary) !important;
            }

            #pageTitle {
                margin: 0px;
            }

            .nav-item > .nav-item-hold {
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

            .error {
                color: red;
            }
        </style>
    @endpush
    @stack('css')
</head>

<body>
<div class="auth-layout-wrap"
     style="background-image: url({{URL::to('/images/login_bg_img.jpg')}})">
    <div class="auth-content">
        <div class="card o-hidden">
            <div class="row">
                <div class="col-12">
                    <div class="p-4">
                        <div class="auth-logo text-center mb-4">
                            <img src="{{URL::to('images/logo.png')}}" alt="">
                        </div>


                        @error('login_error') <p class="error">{{$message}}</p> @enderror


                        <form action="{{URL::to('/login')}}" method="post" autocomplete="off">
                            @csrf
                            <div class="form-group">
                                <label for="email">Email</label>
                                <input id="email" name="email" class="form-control" type="email"
                                       value="{{old('email')}}">
                                @error('email') <p class="error">{{$message}}</p> @enderror
                            </div>
                            <div class="form-group">
                                <label for="password">Password</label>
                                <input id="password" name="password" class="form-control"
                                       type="password" value="{{old('password')}}">
                                @error('password') <p class="error">{{$message}}</p> @enderror
                            </div>
                            <button class="btn btn-primary btn-block mt-2">Entrar</button>

                        </form>
                        <!--
                        <div class="mt-3 text-center">
                            <a href="forgot.html" class="text-muted"><u>Forgot Password?</u></a>
                        </div>
                        -->
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- ============ Body content End ============= -->

    @prepend('scripts')
        <script src="{{URL::to('/js/common-bundle-script.js')}}"></script>
        <script src="{{URL::to('/js/script.js')}}"></script>
        <script src="{{URL::to('/js/sidebar.large.script.js')}}"></script>
        <script src="{{URL::to('/js/customizer.script.js')}}"></script>
        <script src="{{URL::to('/js/form.validation.script.js')}}"></script>
        <script src="{{URL::to('/js/toastr.min.js')}}"></script>
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
