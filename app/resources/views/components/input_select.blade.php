@prepend('css')
    <?php
    if (!isset($_SESSION)) {
        session_start();
    }

    if (!isset($_SESSION['css'])) {
        $_SESSION['css'] = array();
    }

    $term = "select2";
    $css_tag = '<link rel="stylesheet" href="' . URL::to("/css/select2.min.css") . '">';
    if (!in_array($term, $_SESSION['css'])) {
        array_push($_SESSION['css'], $term);
        echo $css_tag;
    }
    ?>
@endprepend
<div class="form-group mb-3">
    <label for="{{$select_id}}" style="display: block;">{{$label}}</label>
    <select id="{{$select_id}}" name="{{$select_name}}" class="form-control" style="width: 100%;"
        {{$required}} {{$multiple}}>
        {{$options}}
    </select>
</div>
@push('scripts')
    <?php
    if (!isset($_SESSION)) {
        session_start();
    }

    if (!isset($_SESSION['scripts'])) {
        $_SESSION['scripts'] = array();
    }

    $term = "select2";
    $script_tag = '<script src="' . URL::to("/js/vendor/select2.full.min.js") . '"></script>';
    if (!in_array($term, $_SESSION['scripts'])) {
        array_push($_SESSION['scripts'], $term);
        echo $script_tag;
    }
    ?>
    <script>
        $(document).ready(function () {
            $('#{{$select_id}}').select2();
        });
    </script>
@endpush
