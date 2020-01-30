<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Validation\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Equipamento;
use App\Historico_Configuracoes;

class EquipamentoController extends Controller
{

    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:" . config('Utilizador_Tipo.1') . "," . config('Utilizador_Tipo.2');
        $this->middleware($verificar_permissoes);
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        return view("pages.equipamento.index")->with([
            'name' => 'Equipamentos',
            'equipamentos' => Equipamento::all()->where('ativo', true),
            'patients' => DB::table('paciente')->select('paciente.id as patient_id', 'paciente.nome as patient_name')->whereNotIn('id', function ($query) {
                $query->select('paciente_id')->from('historico_configuracoes')->where('esta_associado', true)->distinct();
            })->get()
        ]);
    }


    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {

        $dados = $request->validate([
            "nome" => "required|unique:equipamentos",
        ]);


        $access_token = "";
        do {
            $access_token = Str::random(20);
        } while (Equipamento::where("access_token", $access_token)->exists());

        $dados["access_token"] = $access_token;
        $dados["log_utilizador_id"] = Auth::user()->id;
        $equipamento = Equipamento::create($dados);
        $equipamento['esta_associado'] = $equipamento->esta_associado();

        return response()->json([
            'status' => 'ok',
            'redirect' => '/equipamento',
            'equipamento' => $equipamento,
        ]);
    }

    /**
     * Display the specified resource.
     *
     * @param int $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param int $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @param int $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            "not_associate" => "sometimes|boolean",
            "select_patient" => "sometimes|exists:paciente,id",
            "nome_edit" => "required|unique:equipamentos,nome," . $id,
            "token" => "required|max:20|unique:equipamentos,access_token," . $id,
        ]);
        $equipamento = Equipamento::find($request->id);
        $equipamento->nome = $request->nome_edit;
        $equipamento->access_token = $request->token;
        $equipamento->data_update = date('Y-m-d H:i:s');
        $equipamento->log_utilizador_id = auth()->user()->id;
        $equipamento->save();
        
        $this->associate($request, $equipamento);

        return response()->json([
            'status' => 'ok',
            'redirect' => '/equipamento',
        ]);
    }

    public function associate(Request $request, $equipment)
    {
        Historico_Configuracoes::where([
            ['equipamento_id', '=', $equipment->id],
            ['esta_associado', '=', true],
        ])->update(['esta_associado' => false]);

        if(!$request->not_associate){
            $association = new Historico_Configuracoes;
            $association->paciente_id = $request->select_patient;
            $association->equipamento_id = $equipment->id;
            $association->esta_associado = true;
            return $association->save();
        }
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param int $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        $equipamento = Equipamento::find($id);
        //$equipamento->delete();
        $equipamento->ativo = false;
        $equipamento->data_update = date('Y-m-d H:i:s');
        $equipamento->log_utilizador_id = auth()->user()->id;
        $equipamento->save();

        return response()->json([
            'status' => 'ok',
            'redirect' => '/equipamento',
        ]);
    }
}
