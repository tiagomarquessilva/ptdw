<div class="logo">
    <a href="{{URL::to('/')}}">
        <img src="{{URL::to('images/logo.png')}}" alt="">
    </a>
</div>

<div class="menu-toggle">
    <div></div>
    <div></div>
    <div></div>
</div>

<div style="margin: auto"></div>

<div class="header-part-right">
    <!-- Full screen toggle -->
    <i class="i-Full-Screen header-icon d-none d-sm-inline-block" data-fullscreen></i>

    <!-- Notification -->
    <div class="dropdown">
        <div class="badge-top-container" role="button" id="dropdownNotification" data-toggle="dropdown"
             aria-haspopup="true" aria-expanded="false">
            <span class="badge badge-primary" id="notification_badge"></span>
            <i class="i-Bell text-muted header-icon"></i>
        </div>
        <!-- Notification dropdown -->
        <div id="notification_dropdown" class="dropdown-menu dropdown-menu-right notification-dropdown rtl-ps-none"
             aria-labelledby="dropdownNotification" data-perfect-scrollbar data-suppress-scroll-x="true">
            <button type="button" id="button_notifications" class="btn btn-raised btn-raised-primary m-1"
                    style="width: 100%; margin: 0px !important; position: -webkit-sticky; position: sticky; bottom: 0;"
                    onclick="location.href='{{URL::to('/user_profile#notifications')}}';">Todos os Alertas
            </button>
        </div>
    </div>
    <!-- Notificaiton End -->
    <!-- Utilizador avatar dropdown -->
    <div class="dropdown">
        <div class="user col align-self-end">
            <i id="userDropdown" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" class="i-Administrator header-icon"></i>
            <div class="dropdown-menu dropdown-menu-right" aria-labelledby="userDropdown">
                <div class="dropdown-header">
                    <h6 class="heading mb-0 text-left">{{Auth::user()->nome}}</h6>
                    <small class="text-mute"></small>
                </div>
                <div class="dropdown-divider"></div>
                <a class="dropdown-item" href="{{URL::to('/user_profile#personal_info')}}">Ver perfil</a>
                <a class="dropdown-item" href="{{URL::to('/logout')}}">Sign out</a>
            </div>
        </div>
    </div>
</div>
@push('scripts')
    <script>
        // buscar notificações
        function elapsedTime(notification_date) {
            'use strict';
            let elapsed = (new Date().getTime() - Date.parse(notification_date)) / 1000;
            if (elapsed >= 0) {
                const diff = {};

                diff.days = Math.floor(elapsed / 86400);
                diff.hours = Math.floor(elapsed / 3600 % 24);
                diff.minutes = Math.floor(elapsed / 60 % 60);
                diff.seconds = Math.floor(elapsed % 60);

                let message = `${diff.days}d ${diff.hours}h ${diff.minutes}m`;
                message = message.replace(/(?:0. )+/, '');
                return message;
            } else {
                return 0;
            }
        };

        function notifications_to_html(notifications) {
            let notifications_html = document.createDocumentFragment();
            notifications.forEach(function (notification) {
                let notification_type_icon_and_color;
                switch (notification.type) {
                    case "Chamada":
                        notification_type_icon_and_color = "i-Warning-Window text-warning";
                        break;

                    case "Emergência":
                        notification_type_icon_and_color = "i-Danger text-danger";
                        break;

                    default:
                        break;
                }
                let notification_html = document.createElement('div');
                notification_html.id = "notification_" + notification.id;
                notification_html.classList.add("dropdown-item", "d-flex");
                notification_html.innerHTML = '<div class="notification-icon"><i class="' + notification_type_icon_and_color + ' mr-1"></i></div><div class="notification-details flex-grow-1"><p class="m-0 d-flex align-items-center"><span>' + notification.type + '</span><span class="flex-grow-1"></span><span class="text-small text-muted ml-auto">' + elapsedTime(notification.date) + ' atrás</span></p><p class="text-small text-muted m-0">' + notification.pacient_name + " - " + notification.message + '</p></div>';
                notifications_html.appendChild(notification_html);
            });
            document.getElementById("notification_dropdown").prepend(notifications_html);
        }

        function get_unsolved_notifications() {
            $.ajax({
                type: "GET",
                url: "{{URL::to('/notifications/unsolved')}}",
                dataType: "json",
                success: function (data) {
                    notifications_to_html(data);
                    document.getElementById("notification_badge").innerHTML = $("#notification_dropdown .dropdown-item").length;
                    if (data.length > 0) {
                        last_date = data[0].date;
                    }
                },
                error: function () {
                    console.error('>[ERRO]\tErro a obter notificaçoes!');
                }
            });
        }

        let last_date;
        // on page load get all unsolved notifications
        get_unsolved_notifications();

        // check for new notifications for the rest of the time
        setInterval(function () {
            if (last_date != undefined) {
                $.ajax({
                    type: "GET",
                    url: "{{URL::to('/notifications')}}",
                    data: {
                        date: new Date(last_date).toISOString()
                    },
                    dataType: "json",
                    success: function (data) {
                        notifications_to_html(data);
                        document.getElementById("notification_badge").innerHTML = $("#notification_dropdown .dropdown-item").length;
                        if (data.length > 0) {
                            last_date = data[0].date;
                        }
                    },
                    error: function () {
                        console.error('>[ERRO]\tErro a obter notificaçoes!');
                    }
                });
            } else {
                get_unsolved_notifications();
            }

        }, 5000);
    </script>
@endpush
