<div class="side-content-wrap">

    <div class="sidebar-left open rtl-ps-none" data-perfect-scrollbar data-suppress-scroll-x="true">
        <ul class="navigation-left">

            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/')}}">
                    <i class="nav-icon i-Bar-Chart"></i>
                    <span class="nav-text">Painel</span>
                </a>
            </li>

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.2'),config('Utilizador_Tipo.3')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/lista_de_pacientes')}}">
                    <i class="nav-icon i-MaleFemale"></i>
                    <span class="nav-text">Pacientes</span>
                </a>
            </li>
            @endif

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.1')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/health_professionals_list')}}">
                    <i class="nav-icon i-Stethoscope"></i>
                    <span class="nav-text">Profissionais de Saúde</span>
                </a>
            </li>
            @endif

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.2')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/caretakers_list')}}">
                    <i class="nav-icon i-Suitcase"></i>
                    <span class="nav-text">Cuidadores</span>
                </a>
            </li>
            @endif
        <!--
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/calibration')}}">
                    <i class="nav-icon i-Computer-Secure"></i>
                    <span class="nav-text">Calibração</span>
                </a>
            </li>
            -->

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.1'),config('Utilizador_Tipo.2')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/equipamento')}}">
                    <i class="nav-icon i-Address-Book-2"></i>
                    <span class="nav-text">Equipamentos</span>
                </a>
            </li>
            @endif

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.1')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/health_units')}}">
                    <i class="nav-icon i-Hospital"></i>
                    <span class="nav-text">Unidades de Saúde</span>
                </a>
            </li>
            @endif

            @if (Auth::user()->temTipos([config('Utilizador_Tipo.2'),config('Utilizador_Tipo.3')]))
            <li class="nav-item">
                <a class="nav-item-hold" href="{{URL::to('/historic')}}">
                    <i class="nav-icon i-File-Clipboard-File--Text"></i>
                    <span class="nav-text">Histórico</span>
                </a>
            </li>
            @endif

        </ul>
    </div>

    <div class="sidebar-overlay"></div>
</div>
<!--=============== Left side End ================-->
