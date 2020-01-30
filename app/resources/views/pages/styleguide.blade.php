@extends('layout.layout')
@section('content')
    <h1>Paleta de cores</h1>
    <p><b>Cor Primária:</b> #EF7215</p>
    <p><b>Cor Secundária:</b> #FFFFFF</p>
    <hr>
    <h1>Alinhamentos/Posições</h1>
    Para os alinhamentos deve-se <a class="typo_link text-primary" href="https://getbootstrap.com/docs/4.0/layout/grid/"
                                    target="blank">utilizar a grelha
        do Bootstrap</a>.
    <hr>
    <h1>Icons</h1>
    <p>
        Utilizar os <a class="typo_link text-primary" target="blank" href="https://iconsmind.com/view_icons/">icons do
            Iconsmind</a>.
    </p>
    <hr>
    <h1>Tipografia</h1>
    <section class="typography">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div class="row">
                        <!-- left-content -->
                        <div class="col-md-6">
                            <!-- begin::headings -->
                            <div class="card mt-4 mt-4">
                                <div class="card-body">
                                    <div class="card-title">
                                        <h3 class="card-title">Títulos</h3>
                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-6 ">
                                                <h1 class="heading">h1. Heading 1</h1>
                                                <div class="br"></div>
                                                <h2 class="heading">h2. Heading 2</h2>
                                                <div class="br"></div>
                                                <h3 class="heading">h3. Heading 3</h3>
                                                <div class="br"></div>
                                                <h3 class="heading">h3. Heading 3</h3>
                                                <div class="br"></div>
                                                <h4 class="heading">h4. Heading 4</h4>
                                                <div class="br"></div>
                                                <h5 class="heading">h5. Heading 5</h5>
                                                <div class="br"></div>
                                                <h6 class="heading">h6. Heading 6</h6>
                                            </div>
                                            <div class="col-md-6">
                                                <h1 class="heading text-primary">h1. Heading 1</h1>
                                                <div class="card-title"></div>
                                                <h2 class="heading text-secondary">h2. Heading 2</h2>
                                                <div class="br"></div>
                                                <h3 class="heading text-success">h3. Heading 3</h3>
                                                <div class="br"></div>
                                                <h3 class="heading text-danger">h3. Heading 3</h3>
                                                <div class="br"></div>
                                                <h4 class="heading text-warning">h4. Heading 4</h4>
                                                <div class="br"></div>
                                                <h5 class="heading text-info">h5. Heading 5</h5>
                                                <div class="br"></div>
                                                <h6 class="heading text-info">h6. Heading 6</h6>
                                            </div>
                                        </div>

                                        <div class="br"></div>

                                        <div class="row">
                                            <div class="col-md-12">
                                            <span class="section-info">
                                                Titulo secundário pequeno
                                            </span>

                                                <div class="br"></div>

                                                <div class="display-content">
                                                    <h3 class="heading display-1">Display 1</h3>
                                                    <h3 class="heading display-2">Display 2</h3>
                                                    <h3 class="heading display-3">Display 3</h3>
                                                </div>

                                                <div class="br"></div>

                                                <div class="content-section">
                                                    <p class="lead text-mute">
                                                        Parágrafo destacado
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <!-- end::headings -->

                            <!-- begin:general -->
                            <div class="card mt-4 mt-4">
                                <div class="card-body">

                                    <div class="card-title">
                                        <h3 class="card-title">Geral</h3>

                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-12">
                                                <p>You can use the mark tag to
                                                    <mark>highlight</mark>
                                                    text.
                                                </p>
                                                <div class="br"></div>
                                                <p>
                                                    <del>This line of text is meant to be treated as deleted text.</del>
                                                </p>
                                                <div class="br"></div>
                                                <p><s>This line of text is meant to be treated as no longer
                                                        accurate.</s>
                                                </p>
                                                <div class="br"></div>
                                                <p>
                                                    <ins>This line of text is meant to be treated as an addition to the
                                                        document.
                                                    </ins>
                                                </p>
                                                <div class="br"></div>
                                                <p><u>This line of text will render as underlined</u></p>
                                                <div class="br"></div>
                                                <p><small>This line of text is meant to be treated as fine
                                                        print.</small>
                                                </p>
                                                <div class="br"></div>
                                                <p><strong>This line rendered as bold text.</strong></p>
                                                <div class="br"></div>
                                                <p><em>This line rendered as italicized text.</em></p>
                                            </div>

                                        </div>

                                        <div class="br"></div>


                                        <span class="section-info mb-4">
                                        Citações:
                                    </span>

                                        <div class="br"></div>

                                        <blockquote class="blockquote">
                                            <p class="mb-0">Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                                                Integer
                                                posuere erat a ante.</p>
                                            <footer class="blockquote-footer">Someone famous in <cite
                                                    title="Source Title">Source Title</cite></footer>
                                        </blockquote>


                                        <blockquote class="blockquote">
                                            <p class="mb-0">Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                                                Integer
                                                posuere erat a ante.</p>
                                            <footer class="blockquote-footer">Someone famous in <cite
                                                    title="Source Title">Source Title</cite></footer>
                                        </blockquote>
                                    </div>
                                </div>
                            </div>
                            <!-- end:general -->
                        </div>

                        <!-- end::left-content -->

                        <!-- right-content -->
                        <div class="col-md-6 ">
                            <!-- begin::Text -->
                            <div class="card mt-4 mt-4">
                                <div class="card-body">
                                    <h3 class="card-title">Texto</h3>
                                    <div class="card-title">
                                    <span class="section-info">
                                        Exemplos básicos:
                                    </span>

                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-12">
                                                <p><span>Example Text</span></p>
                                                <div class="br"></div>
                                                <p><span class="t-font-bold">Example Bold Text</span></p>
                                                <div class="br"></div>
                                                <p><span class="t-font-bolder">Example Bolder Text</span></p>
                                                <div class="br"></div>
                                                <p><span class="t-font-boldest">Example Boldest Text</span></p>
                                                <div class="br"></div>
                                                <p><span class="t-font-u">Example Uppercase Text</span></p>
                                            </div>

                                        </div>


                                        <span class="section-info">
                                        Exemplo de estados:
                                    </span>

                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-12">

                                                <p><span class="text-success">Success state text</span></p>
                                                <div class="br"></div>
                                                <p><span class="text-warning">Warning state text</span></p>
                                                <div class="br"></div>
                                                <p><span class="text-info">Info state text</span></p>
                                                <div class="br"></div>
                                                <p><span class="text-danger">Danger state text</span></p>
                                                <div class="br"></div>
                                                <p><span class="text-primary">Primary state text</span></p>
                                            </div>

                                        </div>

                                    </div>
                                </div>
                            </div>
                            <!-- end::text -->

                            <!-- begin::links -->
                            <div class="card mt-4 mt-4">
                                <div class="card-body">

                                    <div class="card-title">
                                        <h3 class="card-title">Links</h3>
                                        <span class="section-info">
                                        Exemplos de links básicos:
                                    </span>

                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-12">
                                                <p><a href="" class="typo_link text-primary">Example Text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-primary t-font-bold">Example Bold
                                                        Text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-primary t-font-bolder">Example
                                                        Bolder
                                                        Text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-primary t-font-boldest">Example
                                                        Boldest
                                                        Text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-primary t-font-u">Example Uppercase
                                                        Text</a></p>
                                            </div>

                                        </div>


                                        <span class="section-info">
                                        Exemplos de estados:
                                    </span>

                                        <div class="row mt-4 mb-4">
                                            <div class="col-md-12">
                                                <p><a href="" class="typo_link text-success">Success state text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-warning">Warning state text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-info">Info state text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-danger">Danger state text</a></p>
                                                <div class="br"></div>
                                                <p><a href="" class="typo_link text-primary">Primary state text</a></p>
                                            </div>

                                        </div>

                                    </div>
                                </div>
                            </div>
                            <!-- end::links -->

                            <!-- divider -->
                            <div class="card mt-4 mt-4">
                                <div class="card-header bg-transparent ">
                                    <h3 class="card-title">Divisor</h3>
                                </div>
                                <div class="card-body">
                                    <div class="divider">
                                        <span></span>
                                        <span>or</span>
                                        <span></span>
                                    </div>
                                </div>
                            </div>
                            <!-- end::divider -->
                        </div>
                        <!-- end::right-content -->
                    </div>
                </div>
            </div>
        </div>
    </section>
    <hr>
    <h1>Tabs</h1>
    <p>
        Estas são as tabs a utilizar. Devem sempre ter um icon.
    </p>
    <ul class="nav nav-tabs" id="myIconTab" role="tablist">
        <li class="nav-item">
            <a class="nav-link active" id="home-icon-tab" data-toggle="tab" href="#homeIcon" role="tab"
               aria-controls="homeIcon" aria-selected="true"><i class="i-Home1 mr-1"></i>Home</a>
        </li>
        <li class="nav-item">
            <a class="nav-link" id="profile-icon-tab" data-toggle="tab" href="#profileIcon" role="tab"
               aria-controls="profileIcon" aria-selected="false"><i class="i-Home1 mr-1"></i> Profile</a>
        </li>
        <li class="nav-item">
            <a class="nav-link" id="contact-icon-tab" data-toggle="tab" href="#contactIcon" role="tab"
               aria-controls="contactIcon" aria-selected="false"><i class="i-Home1 mr-1"></i> Contact</a>
        </li>
    </ul>
    <div class="tab-content" id="myIconTabContent">
        <div class="tab-pane fade show active" id="homeIcon" role="tabpanel" aria-labelledby="home-icon-tab">
            Etsy mixtape wayfarers, ethical wes anderson tofu before they sold out mcsweeney's organic lomo retro fanny
            pack lo-fi farm-to-table readymade. Messenger bag gentrify pitchfork tattooed craft beer, iphone skateboard
            locavore.
        </div>
        <div class="tab-pane fade" id="profileIcon" role="tabpanel" aria-labelledby="profile-icon-tab">
            Etsy mixtape wayfarers, ethical wes anderson tofu before they sold out mcsweeney's organic lomo retro fanny
            pack lo-fi farm-to-table readymade. Messenger bag gentrify pitchfork tattooed craft beer, iphone skateboard
            locavore.
        </div>
        <div class="tab-pane fade" id="contactIcon" role="tabpanel" aria-labelledby="contact-icon-tab">
            Etsy mixtape wayfarers, ethical wes anderson tofu before they sold out mcsweeney's organic lomo retro fanny
            pack lo-fi farm-to-table readymade. Messenger bag gentrify pitchfork tattooed craft beer, iphone skateboard
            locavore.
        </div>
    </div>
    <hr>
    <h1>Listas</h1>
    <p>
        Esta é a lista a utilizar. Se for necessário colocar um icon/badge numa linha alinhar o texto à esquerda e o
        icon/badge à direita. Segue uma lista com icons.
    </p>
    @component('components.list')
        @slot('items')
            <li class="list-group-item">
                <div class="row">
                    <div class="col text-left">
                        Placeholder
                    </div>
                    <div class="col text-right">
                        <i class="i-Background"></i>
                    </div>
                </div>
            </li>
            <li class="list-group-item">
                <div class="row">
                    <div class="col text-left">
                        Placeholder
                    </div>
                    <div class="col text-right">
                        <i class="i-Background"></i>
                    </div>
                </div>
            </li>
            <li class="list-group-item">
                <div class="row">
                    <div class="col text-left">
                        Placeholder
                    </div>
                    <div class="col text-right">
                        <i class="i-Background"></i>
                    </div>
                </div>
            </li>
        @endslot
    @endcomponent
    <hr>
    <h1>Badges</h1>
    <p>
        Estes são os badges a utilizar.
    </p>
    <span class="badge badge-primary p-1">Primário</span>
    <span class="badge badge-secondary p-1">Secundário</span>
    <span class="badge badge-success p-1">Successo</span>
    <span class="badge badge-danger p-1">Perigo</span>
    <span class="badge badge-warning p-1">Aviso</span>
    <span class="badge badge-info p-1">Informação</span>
    <hr>
    <h1>Cartões</h1>
    <p>
        Estes são os cartões a utilizar. Em caso de existirem botões nos cartões estem devem estar colocados no canto
        inferior direito do mesmo. Os cartões podem ter a dimensão que for mais conveninente.
    </p>
    {{-- card:start --}}
    @component('components.card')
        @slot('title')
            Título do Cartão
        @endslot
        @slot('body')
            Corpo do Cartão
        @endslot
    @endcomponent
    {{-- card:end --}}
    <br>
    <p>Cartão com imagem.</p>
    @component('components.card_image')
        @slot('title')
            Título do Cartão
        @endslot
        @slot('body')
            Corpo do Cartão
        @endslot
        @slot('img')
        {{URL::to('/images/login_bg_img.jpg')}}
        @endslot
        @slot('img_alt')
        @endslot
    @endcomponent
    <hr>
    <h1>Elementos do Formulário</h1>
    <p>Em todos os formulários colocar o atributo novalidate e a class needs-validation para ter mensagens de validação
        personalizada e não as padrão.
        Exemplo: &lt;form action="" method="get" class="needs-validation" novalidate&gt;&lt;/form&gt;</p>
    @component('components.input_text_email_num_date')
        @slot('label')
            Texto/Número/Datas:
        @endslot
        @slot('input_id')
            input
        @endslot
        @slot('type')
            text
        @endslot
        @slot('required')
            {{-- Se é obrigatório preencher com required se não não colocar nada --}}
            required
        @endslot
        @slot('placeholder')
            placeholder
        @endslot
        @slot('value')
        @endslot
    @endcomponent
    {{-- select:start --}}
    @component('components.input_select')
        @slot('label')
            (Single ou Multiple) Select:
        @endslot
        @slot('select_id')
            select
        @endslot
        @slot('select_name')
            select
        @endslot
        @slot('options')
            <option value="AL">Alabama</option>
            <option value="WY">Wyoming</option>
        @endslot
        @slot('multiple')
            {{-- Se multiselect preencher com multiple se não não colocar nada --}}
            multiple
        @endslot
        @slot('required')
            {{-- Se é obrigatório preencher com required se não não colocar nada --}}
            required
        @endslot
    @endcomponent
    {{-- select:end --}}
    @component('components.input_switch')
        @slot('label')
            Switch
        @endslot
        @slot('switch_id')
            switch
        @endslot
        @slot('checked')
            {{-- Se é para começar ativado com checked se não não colocar nada --}}
            checked
        @endslot
        @slot('required')
            {{-- Se é obrigatório preencher com required se não não colocar nada --}}
            required
        @endslot
    @endcomponent
    @component('components.input_radio')
        @slot('radio_id')
            radio
        @endslot
        @slot('label')
            Radio
        @endslot
        @slot('name')
            question
        @endslot
        @slot('value')
            1
        @endslot
    @endcomponent
    @component('components.input_checkbox')
        @slot('checkbox_id')
            checkbox
        @endslot
        @slot('label')
            Checkbox
        @endslot
        @slot('checked')
            {{-- Se é para começar ativado com checked se não não colocar nada --}}
            checked
        @endslot
        @slot('required')
            {{-- Se é obrigatório preencher com required se não não colocar nada --}}
            required
        @endslot
    @endcomponent
    <hr>
    <h1>Notificações</h1>
    <p>
        Estas são as notificações a usar. Devem ser usadas nas situações descritas nos botões que as acionam.
    </p>
    @component('components.button_success')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Notificação de Sucesso
        @endslot
        @slot('button_id')
            toastr_success
        @endslot
    @endcomponent
    @push('scripts')
        <script>
            $(document).ready(function () {
                $('#toastr_success').on("click", function (e) {
                    toastr.success("Mensagem de Sucesso", "Titulo");
                });
            });
        </script>
    @endpush
    @component('components.button_danger')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Notificação de Erro
        @endslot
        @slot('button_id')
            toastr_error
        @endslot
    @endcomponent
    @push('scripts')
        <script>
            $(document).ready(function () {
                $('#toastr_error').on("click", function (e) {
                    toastr.error("Mensagem de Erro", "Titulo");
                });
            });
        </script>
    @endpush
    @component('components.button_warning')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Notificação de Aviso
        @endslot
        @slot('button_id')
            toastr_warning
        @endslot
    @endcomponent
    @push('scripts')
        <script>
            $(document).ready(function () {
                $('#toastr_warning').on("click", function (e) {
                    toastr.warning("Mensagem de Warning", "Titulo");
                });
            });
        </script>
    @endpush
    @component('components.button_info')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Notificação de Informação
        @endslot
        @slot('button_id')
            toastr_info
        @endslot
    @endcomponent
    @push('scripts')
        <script>
            $(document).ready(function () {
                $('#toastr_info').on("click", function (e) {
                    toastr.info("Mensagem de Informação", "Titulo");
                });
            });
        </script>
    @endpush
    <hr>
    <h1>Breadcrumbs</h1>
    <p>
        Estas são as breadcrumbs a usar. A página mais baixa na hierarquia deve-se encontrar mais à direita.
    </p>
    @component('components.breadcrumbs')
        @slot('path')
            <li><a href="/">Home</a></li>
            <li><a href="/styleguide">Guia de Estilos</a></li>
        @endslot
    @endcomponent
    <hr>
    <h1>Botões</h1>
    <p>
        Estes são os botões a utilizar. Devem ser usados nas situações descritas nos mesmos. Todas as palavras devem
        começar
        por maiscula.
    </p>
    {{-- button_primary:start --}}
    @component('components.button_primary')
        @slot('type')
            button
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Usar Este Botão Para Ações Que Queremos Que O User Faça
        @endslot
        @slot('button_id')
            button_primary
        @endslot
    @endcomponent
    {{-- button_primary:end --}}
    @component('components.button_secondary')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Usar Este Botão Para Ações de Retorno e Cancelamento
        @endslot
        @slot('button_id')
            button_secondary
        @endslot
    @endcomponent
    @component('components.button_success')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Usar Este Botão Para Ações de Confirmação
        @endslot
        @slot('button_id')
            button_success
        @endslot
    @endcomponent
    @component('components.button_danger')
        @slot('type')
        @endslot
        @slot('extra')@endslot
        @slot('text')
            Usar Este Botão Para Ações Destrutivas
        @endslot
        @slot('button_id')
            button_danger
        @endslot
    @endcomponent
    @component('components.button_warning')
        @slot('type')
        @endslot
        @slot('extra')

        @endslot
        @slot('text')
            Usar Este Botão Para Ações de Aviso
        @endslot
        @slot('button_id')
            button_warning
        @endslot
    @endcomponent
    @component('components.button_info')
        @slot('type')
        @endslot
        @slot('extra')

        @endslot
        @slot('text')
            Usar Este Botão Para Ações Informativas
        @endslot
        @slot('button_id')
            button_info
        @endslot
    @endcomponent
    <hr>
    <h1>Dropdowns</h1>
    <p>
        Estes serão os dropdowns a serem utilizados.
    </p>
    {{-- dropdown:start --}}
    @component('components.input_dropdown_primary')
        @slot('text')
            Dropdown
        @endslot
        @slot('dropdown_items')
            <a class="dropdown-item" href="#">Action</a>
            <a class="dropdown-item" href="#">Another action</a>
            <a class="dropdown-item" href="#">Something else here</a>
            <div class="dropdown-divider"></div>
            <a class="dropdown-item" href="#">Separated link</a>
        @endslot
    @endcomponent
    {{-- dropdown:end --}}
    @component('components.input_dropdown_secondary')
        @slot('text')
            Dropdown
        @endslot
        @slot('dropdown_items')
            <a class="dropdown-item" href="#">Action</a>
            <a class="dropdown-item" href="#">Another action</a>
            <a class="dropdown-item" href="#">Something else here</a>
            <div class="dropdown-divider"></div>
            <a class="dropdown-item" href="#">Separated link</a>
        @endslot
    @endcomponent
    <hr>
    <h1>Tabelas</h1>
    <p>Se for necessário colocar filtros na mesma estes serão em forma de dropdown à direita
        do "Pesquisar". Se for necessário colocar botões estes serão colocados cartão de topo alinhados à direita. Se
        uma
        célula da tabela for de ação e contiver apenas uma ação deve-se usar um botão, se não utilizar uma dropdown. Se
        uma
        célula contiver mais que um valor então deve-se usar badges para esses valores. Em baixo mostra uma tabela com
        todas
        essas opções.
    </p>
    {{-- table:start --}}
    @component('components.table')
        @slot('table_id')
            styleguide_table
        @endslot
        @slot('title')
            Tabela
        @endslot
        @slot('aria_describedby')
            Tabela de exemplo no guia de estilos
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões antes dos filtros. é aqui que devem aparecer os botões de adicionar --}}
            {{-- button_primary:start --}}
            @component('components.button_primary')
                @slot('type')
                    button
                @endslot
                @slot('extra')@endslot
                @slot('text')
                    Adicionar
                @endslot
                @slot('button_id')
                    button_add_example
                @endslot
            @endcomponent
            {{-- button_primary:end --}}
        @endslot
        @slot('search_placeholder')
            Procurar na Tabela...
        @endslot
        @slot('filters')
            {{-- dropdown:start --}}
            @component('components.input_dropdown_secondary')
                @slot('text')
                    Filtros
                @endslot
                @slot('dropdown_items')
                    <div class="dropdown-item">
                        @component('components.input_text_email_num_date')
                            @slot('label')
                                Exemplo Filtro:
                            @endslot
                            @slot('input_id')
                                input
                            @endslot
                            @slot('type')
                                text
                            @endslot
                            @slot('required')
                                {{-- Se é obrigatório preencher com required se não não colocar nada --}}
                            @endslot
                            @slot('placeholder')
                                Procurar
                            @endslot
                            @slot('value')
                            @endslot
                        @endcomponent
                    </div>
                @endslot
            @endcomponent
            {{-- dropdown:end --}}
        @endslot
        @slot('thead')
            <tr>
                <th>Placeholder</th>
                <th>Placeholder</th>
                <th>Placeholder</th>
                <th>Placeholder</th>
            </tr>
        @endslot
        @slot('tbody')
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
            <tr>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
                <td>Placeholder</td>
            </tr>
        @endslot
    @endcomponent
    {{-- table:end --}}
    <hr>
    <h1>Modal</h1>
    <p>O modal a ser utilizado encontra-se em baixo. Se o modal incorporar um formulário o botão de submissão do mesmo
        deve-se enontrar à direita do botão "Fechar". Clicar no botão para ver o modal.
    </p>
    @component('components.button_primary')
        @slot('type')button
        @endslot
        @slot('extra')
            data-toggle="modal" data-target="#modal"
        @endslot
        @slot('text')
            Ver Modal
        @endslot
        @slot('button_id')
            button_modal
        @endslot
    @endcomponent
    {{-- modal:start --}}
    @component('components.modal')
        @slot('id')
            modal
        @endslot
        @slot('aria_labelledby')
            Modal de exemplo do guia de estilos
        @endslot
        @slot('title')
            Titulo
        @endslot
        @slot('body')
            Corpo do Modal
        @endslot
        @slot('buttons')
            {{-- Adicionar aqui HTML para botões que ficam à direita do fechar o modal. É aqui que devem aparecer os botões de submeter --}}
        @endslot
    @endcomponent
    {{-- modal:end --}}
    <hr>
    <h1>Gráficos</h1>
    <p>
        Utilizar os <a class="typo_link text-primary" target="blank" href="https://www.chartjs.org/samples/latest/">gráficos
            do ChartJS</a>. As cores das linhas, pontos, barras, etc. devem estar de acordo com a paleta de cores do
        website.
    </p>
@endsection
