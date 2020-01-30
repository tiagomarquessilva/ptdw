{{-- CSS --}}
<style>
    .modal-dialog {
        margin: 0;
        position: absolute;
        right: 0;
        max-width: 95%;
        width: auto !important;
        display: inline-block;
        border-left: 1px solid var(--primary);
    }

    .modal-content {
        height: 100vh;
    }

    .modal-body {
        overflow-y: scroll;
    }

    .modal-dialog-slideout {
        min-height: 100%;
        margin: 0 0 0 auto;
        background: #fff;
    }

    .modal.fade .modal-dialog.modal-dialog-slideout {
        -webkit-transform: translate(100%, 0) scale(1);
        transform: translate(100%, 0) scale(1);
    }

    .modal.fade.show .modal-dialog.modal-dialog-slideout {
        -webkit-transform: translate(0, 0);
        transform: translate(0, 0);
        display: flex;
        align-items: stretch;
        -webkit-box-align: stretch;
        height: 100%;
    }

    .modal.fade.show .modal-dialog.modal-dialog-slideout {
        overflow-y: auto;
        overflow-x: hidden;
    }

    .modal-dialog-slideout .modal-content {
        border: 0;
    }

    .modal-dialog-slideout .modal-header,
    .modal-dialog-slideout .modal-footer {
        height: 69px;
        display: block;
    }

    .modal-dialog-slideout .modal-header h5 {
        float: left;
    }
</style>
{{-- HTML --}}
<div class="modal right fade" id="{{$id}}" role="dialog" aria-labelledby="{{$aria_labelledby}}"
     aria-hidden="true">
    <div class="modal-dialog modal-dialog-slideout" role="document" style="width: 100%;">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">{{$title}}</h5>
            </div>
            <div class="modal-body">
                {{$body}}
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-raised btn-raised-secondary m-1"
                        data-dismiss="modal" data-target="{{$id}}">Fechar
                </button>
                {{$buttons}}
            </div>
        </div>
    </div>
</div>
