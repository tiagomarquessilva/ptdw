<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;
use App\PS_List;
use App\PS_Function;
use App\health_unit;
use App\Utilizador;
use App\User_Health_Unit;
use App\Utilizador_Tipo;
use App\Paciente_Utilizador;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class PS_ListController extends Controller
{
    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:". config('Utilizador_Tipo.1');
        $this->middleware($verificar_permissoes);
    }
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $ps_list = PS_List::all()->map(function ($p) {
            return [
                'nome' => $p->nome,
                'email' => $p->email,
                'contacto' => $p->contacto,
                'tipos' => json_decode($p->tipos, true),
                'funcao' => json_decode($p->funcao, true),
            ];
        });
        $types = DB::table('tipos')->whereRaw('nome NOT ILIKE \'%profissional%saude%\'')->orderBy('nome')->get();
        $ps_functions = PS_Function::orderBy('nome')->get();
        $health_unit = health_unit::where('ativo', '=', true)->orderBy('nome')->get();

        return view('pages.ps_list')->with(['name' => 'Profissionais de Saúde', 'ps_list' => $ps_list,
            'types' => $types, 'ps_functions' => $ps_functions, 'health_unit' => $health_unit]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\Response
     * @throws \Illuminate\Validation\ValidationException
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ps_name' => 'required|max:255',
            'ps_contact' => 'required|digits:9|unique:utilizador,contacto',
            'ps_email' => 'required|email|max:255|unique:utilizador,email',
            'ps_password' => 'required|max:255',
            'ps_health_unit' => 'required',
            'ps_function' => 'required'
        ]);

        if ($validator->fails())
            return json_encode([
                'success' => false,
                'insert_errors' => false,
                'validate_errors' => $validator->errors()
            ]);
        else
            try {
                $request['ps_password'] = bcrypt($request['ps_password']);

                DB::select('SELECT * FROM registo_ps(?, ?)', [json_encode($request->all()), auth()->user()->id]);

                redirect('health_professionals_list')->with('ps_inserted', true);

                return json_encode([
                    'success' => true,
                    'insert_errors' => false,
                    'validate_errors' => null
                ]);
            } catch (Exception $e) {
                return json_encode([
                    'success' => false,
                    'insert_errors' => true,
                    'validate_errors' => null
                ]);
            }
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param string $email
     * @return \Illuminate\Http\Response
     */
    public function edit($email)
    {
        $ps_list = DB::table('lista_ps')
            ->where('email', $email)
            ->get(['email', 'unidades_saude', 'tipos', 'funcao'])
            ->map(function ($p) {
                return [
                    'unidades_saude' => json_decode($p->unidades_saude, true),
                    'tipos' => json_decode($p->tipos, true),
                    'funcao' => json_decode($p->funcao, true),
                ];
            });

        return response()->json(['ps_list' => $ps_list, 'ps_type' => DB::table('tipos')->whereRaw('nome ILIKE \'%profissional%saude%\'')->get('id')[0]->id], 200);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @param string $email
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $email)
    {
        $validator = Validator::make($request->all(), [
            'edit_ps_health_unit' => 'required',
            'edit_ps_function' => 'required'
        ]);

        if ($validator->fails())
            return json_encode([
                'success' => false,
                'update_errors' => false,
                'validate_errors' => $validator->errors()
            ]);
        else
            try {
                DB::select('SELECT * FROM atualiza_ps(?, ?, ?)', [json_encode($request->all()), auth()->user()->id, $email]);

                redirect('health_professionals_list')->with('ps_updated', true);

                return json_encode([
                    'success' => true,
                    'update_errors' => false,
                    'validate_errors' => null
                ]);
            } catch (Exception $e) {
                return json_encode([
                    'success' => false,
                    'update_errors' => $e->getMessage(),
                    'validate_errors' => null
                ]);
            }
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param string $email
     * @return \Illuminate\Http\Response
     */
    public function destroy($email)
    {
        $log_user = auth()->user()->id;
        $ps_id = Utilizador::select('id')->where('email', $email)->first();
        $ps = Utilizador::where('email', $email)->first();

        $ps->ativo = false;
        $ps->data_update = Carbon::now();
        $ps->log_utilizador_id = $log_user;

        if ($ps->save()) {
            Paciente_Utilizador::where('utilizador_id', $ps_id['id'])
                ->where('ativo', true)
                ->update(['data_update' => Carbon::now(), 'ativo' => false,'log_utilizador_id' => $log_user]);
            User_Health_Unit::where('utilizador_id', $ps_id['id'])
                ->where('ativo', true)
                ->update(['data_update' => Carbon::now(), 'ativo' => false,'log_utilizador_id' => $log_user]);
            Utilizador_Tipo::where('utilizador_id', $ps_id['id'])
                ->where('ativo', true)
                ->update(['data_update' => Carbon::now(), 'ativo' => false,'log_utilizador_id' => $log_user]);
            return redirect('health_professionals_list')->with('ps_deleted', true);
        } else return redirect('health_professionals_list')->with('ps_deleted', false);
    }
}
