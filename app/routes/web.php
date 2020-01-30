<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
use App\Http\Controllers\notifications_controller;
use Illuminate\Support\Facades\Auth;

Route::group(['middleware'=>'auth'],function (){

    /**
     * rotas de utilizador e notificações
     */
    Route::get('/user_profile', function () {
        $notifications = new notifications_controller;
        return view('pages.user_profile')->with(['name'=>'Perfil', 'user_name'=>Auth::user()->nome, 'user_email'=>Auth::user()->email, 'user_contact'=>Auth::user()->contacto, 'notifications'=>$notifications->index()]);
    });
    Route::put('/user_profile', 'LoginController@update_user_info');

    Route::get('/notifications', 'notifications_controller@index_unsolved_notifications_after');
    Route::get('/notifications/unsolved', 'notifications_controller@index_unsolved_notifications');
    Route::put('/notifications/{id}', 'notifications_controller@update');

    /**
     * rota de painel
     */

    Route::get('/', function () {
        return view('pages.welcome')->with(['name'=>'Painel']);
    });


    /**
     * rotas de profissional de saude
     */
    Route::resource('/health_professionals_list', 'PS_ListController');


    /**
     * rotas de cuidadores
     */
    Route::resource('/caretakers_list', "CuidadorController");



    /**
     * rotas equipamentos
     */
    Route::resource('/equipamento', 'EquipamentoController')->except([
        'create', 'show', "edit"
    ]);;


    /**
     * rotas calibração
     */
    Route::post("/calibracao","CalibracaoController@store");
    Route::get("/calibracao/{equipamento_id}","CalibracaoController@index");
    Route::get("/calibracao/{equipamento_id}/getUltimoRegisto","CalibracaoController@getUltimoRegisto");
    Route::get("/historicoConfiguracoes/{paciente_id}","CalibracaoController@historicoConfiguracoes");

    /**
     * rotas unidades de saude
     */
    Route::resource('health_units', 'health_unit_controller')->except([
        'create', 'show', 'edit'
    ]);

    /**
     * rotas historico
     */
    Route::get('/historic', 'HistoricController@index');
    Route::get('/historic/patients', 'HistoricController@get_historic_patients');
    Route::get('/historic/patient/{id}', 'HistoricController@get_historic_patient');
    Route::get('/historic/health_unit/{id}', 'HistoricController@get_historic_health_units');

});

/**
 * rotas de login
 */

Route::get('/login',"LoginController@index")->name("login");
Route::post('/login',"LoginController@login")->name("login");
Route::get('/logout',"LoginController@logout")->name("logout");

Route::get('/styleguide', function () {
    return view('pages.styleguide')->with(['name'=>'Guia de Estilos']);
});

### PACIENTES ##

Route::get('/lista_de_pacientes', 'Patient\PatientController@index')->name('Pacientes');
Route::post('/criar_paciente', 'Patient\PatientController@store')->name('Pacientes');
Route::post('/paciente/{id}', 'Patient\PatientController@show')->name('Pacientes');
Route::post('/editar_paciente/{id}', 'Patient\PatientController@update')->name('Pacientes');
Route::post('/eliminar_paciente/{id}','Patient\PatientController@destroy')->name('Pacientes');

Route::post('/eliminar_nota/{id}','Note\NoteController@destroy')->name('Notas');
Route::post('/criar_nota','Note\NoteController@store')->name('Notas');
Route::post('/notas/{id}','Note\NoteController@index')->name('Notas');

Route::post('/eliminar_lembrete/{id}','Reminder\ReminderController@destroy')->name('Lembretes');
Route::post('/criar_lembrete','Reminder\ReminderController@store')->name('Lembretes');
Route::post('/lembretes/{id}','Reminder\ReminderController@index')->name('Lembretes');

################




