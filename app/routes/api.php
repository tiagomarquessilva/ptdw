<?php

use Illuminate\Http\Request;

use App\Historico_Valores;
use App\Equipamento;
use App\Historico_Configuracoes;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:api')->get('/user', function (Request $request) {
    return $request->user();
});
/**
 * TODO:
 * Passar  o codigo seguinte para um controlador de de API
 * verificar chave de api e returnar o id do equipamento
 * verificar qual o id do paciente que tem o equipmaneto
 * etc.
 */


Route::post("/registar_dados", function(Request $request){
    try{

        $dados = $request->all();
        //verificar token de acesso e buscar ID
        $equipmaneto = Equipamento::where("access_token",$dados["access_token"])->firstOrFail();
        $equipmaneto_id = $equipmaneto["id"];

        //ir buscar ID paciente
        $historico = Historico_Configuracoes::where("equipamento_id",$equipmaneto["id"])
            ->where("esta_associado",true)
            ->latest("id")
            ->get()
            ->first();


        $CalibracaoAtual = Historico_Valores::create([
            "emg"   => doubleval($dados["emg"]),
            "bc"    => intval($dados["bc"]),
            "paciente_id" => $historico["paciente_id"],
            "equipamento_id" => $equipmaneto_id,
            "data_registo"  => now()
        ]);

        return "successo";
    }catch (Exception $e) {
        echo "erro : " + $e;
    }
});


Route::get("/obter_configuracao",function (Request $request){
    try{
        //check access token e obter o ID
        $dados = $request->all();
        $equipmaneto = Equipamento::where("access_token",$dados["access_token"])->firstOrFail();

        $dadosCalibracao = Historico_Configuracoes::where("equipamento_id",$equipmaneto["id"])
            ->where("esta_associado",true)
            ->latest("id")
            ->get()
            ->first();

        unset($dadosCalibracao["id"]);
        unset($dadosCalibracao["paciente_id"]);
        unset($dadosCalibracao["equipamento_id"]);
        unset($dadosCalibracao["data_registo"]);
        unset($dadosCalibracao["esta_associado"]);

        echo $dadosCalibracao->toJson();

    }catch (Exception $e) {
        //echo 'Caught exception: ',  $e->getMessage(), "\n";
        echo "{erro:'sem dados de calibração'}";
    }



});
// Rotas para o equipamento
// chamada = 1, emergência = 2
Route::post('/send_alert', 'notifications_controller@store_notification');
