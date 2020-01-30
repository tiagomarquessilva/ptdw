<?php

namespace App\Http\Controllers;

use App\Historico_Configuracoes;
use Illuminate\Http\Request;

use App\Historico_Valores;

class CalibracaoController extends Controller
{

    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:".config('Utilizador_Tipo.2');
        $this->middleware($verificar_permissoes);
    }

    public function index($equipamento_id)
    {

        //get paciente id for past configs
        //ou por parametro depois da associação

        //ou por um registo ja existente
        $paciente_id = Historico_Configuracoes::where("equipamento_id", $equipamento_id)
            ->latest("id")
            ->get()
            ->first();
        $paciente_id = $paciente_id["paciente_id"];

        return view('pages.calibration')->with([
            'name' => 'Calibração',
            'equipamento_id' => $equipamento_id,
            'paciente_id' => $paciente_id,
        ]);
    }

    public function historicoConfiguracoes($paciente_id)
    {
        return Historico_Configuracoes::orderBy('data_registo', 'DESC')
            ->where('paciente_id', $paciente_id)
            ->get()
            ->toJson();
    }

    public function getUltimoRegisto(Request $request)
    {
        $id_registo = $request->input("id_registo");
        $equipamento_id = $request->route("equipamento_id");
        $tempo = $request->input("tempo");

        $dados = Historico_Valores::where('id', ">", $id_registo)
            ->where('equipamento_id', $equipamento_id)
            ->where("data_registo", '>', $tempo)
            ->get();
        return response()->json($dados);
    }

    public function store(Request $request)
    {


        $dados = $request->validate([
            "bpm_min" => "required",
            "bpm_max" => "required",
            "emg_min" => "required",
            "emg_max" => "required",
            //"paciente_id"=> "required|exists:paciente,id",
            "paciente_id" => "required",
            "equipamento_id" => "required|exists:equipamentos,id"
        ]);

        //update registos antrioires para falso
        Historico_Configuracoes::where('equipamento_id', $dados["equipamento_id"])
            ->update(['esta_associado' => false]);

        $dados['esta_associado'] = true;
        $dados['data_registo'] = now();

        //add modal and save data
        $configuracao = Historico_Configuracoes::create($dados);


        //copiar valores registados para historico de valores


        return response()->json([
            'status' => 'ok',
            'redirect' => '/equipamento',
        ]);
    }
}
