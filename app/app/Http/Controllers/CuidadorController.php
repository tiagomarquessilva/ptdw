<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Exception;
use App\Patient;
use App\Utilizador;
use App\Paciente_Utilizador;
use App\User_Health_Unit;
use App\User_Type;

class CuidadorController extends Controller
{
    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:" . config('Utilizador_Tipo.2');
        $this->middleware($verificar_permissoes);
    }

    // lista os cuidadores da U.S. do P.S. loggado e os pacientes ao seu cuidador
    public function index()
    {
        $health_unit = DB::table('unidade_saude AS u_s')
            ->join('utilizador_unidade_saude AS u_s_s', 'u_s.id', '=', 'u_s_s.unidade_saude_id')
            ->where('u_s_s.utilizador_id', '=', auth()->user()->id)
            ->get(['u_s.id']);

        $id_caretaker = DB::table('tipos')->whereRaw('nome ILIKE \'%cuidador%\'')->get(['id'])[0]->id;

        $v_health_unit = array();

        foreach ($health_unit as $h) array_push($v_health_unit, $h->id);

        $caretakers = DB::table('utilizador AS u')
            ->join('utilizador_tipo AS u_t', 'u_t.utilizador_id', '=', 'u.id')
            ->join('utilizador_unidade_saude AS u_u_s', 'u_u_s.utilizador_id', '=', 'u.id')
            ->join('unidade_saude AS u_s', 'u_s.id', '=', 'u_u_s.unidade_saude_id')
            ->join('paciente_utilizador AS p_u', 'p_u.utilizador_id', '=', 'u.id')
            ->join('paciente AS p', 'p.id', '=', 'p_u.paciente_id')
            ->where('u_t.tipo_id', '=', $id_caretaker)
            ->whereIn('u_u_s.unidade_saude_id', $v_health_unit)
            ->where('u.ativo', '=', true)
            ->groupBy(['u.nome', 'u.email', 'u.contacto'])
            ->orderBy('u.nome')
            ->get(['u.nome', 'u.email', 'u.contacto', DB::raw('to_json(array_agg(DISTINCT u_s.*)) AS unidades_saude'),
                DB::raw('to_json(array_agg(DISTINCT p.*)) AS pacientes')])
            ->map(function ($c) {
                return [
                    'name' => $c->nome,
                    'email' => $c->email,
                    'contact' => $c->contacto,
                    'health_units' => json_decode($c->unidades_saude, true),
                    'patients' => json_decode($c->pacientes, true),
                ];
            });

        $patients = Patient::where('ativo', '=', true)->whereIn('unidade_saude_id', $v_health_unit)->orderBy('nome', 'asc')->get();

        return view("pages.caretakers_list")->with([
            'name' => 'Cuidadores',
            'caretakers' => $caretakers,
            'patients' => $patients
        ]);
    }

    //
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            "caretaker_name" => "required|max:255",
            "caretaker_contact" => "required|digits:9|unique:utilizador,contacto",
            "caretaker_email" => "required|email|max:255|unique:utilizador,email",
            "caretaker_password" => "required|max:255",
            "caretaker_patients" => "required"
        ]);

        if ($validator->fails())
            return json_encode([
                'success' => false,
                'insert_errors' => false,
                'validate_errors' => $validator->errors()
            ]);
        else
            try {
                $saved = true;
                $id_caretaker = DB::table('utilizador')->insertGetId(
                    [
                        'nome' => $request['caretaker_name'],
                        'password' => bcrypt($request['caretaker_password']),
                        'contacto' => $request['caretaker_contact'],
                        'email' => $request['caretaker_email'],
                        'ativo' => true,
                        'log_utilizador_id' => auth()->user()->id
                    ]
                );

                if (isset($id_caretaker)) {
                    $caretaker_type = new User_Type();
                    $caretaker_type->utilizador_id = $id_caretaker;
                    $caretaker_type->tipo_id = DB::table('tipos')->whereRaw('nome ILIKE \'%cuidador%\'')->get(['id'])[0]->id;
                    $caretaker_type->ativo = true;
                    $caretaker_type->log_utilizador_id = auth()->user()->id;

                    if ($caretaker_type->save()) {
                        $patients = $request['caretaker_patients'];
                        $health_units_patients = array();
                        $equals = false;
                        foreach ($patients as $v) {
                            $id = Patient::where('id', '=', intval($v))->orderBy('id')->get(['unidade_saude_id'])[0]->unidade_saude_id;

                            foreach ($health_units_patients as $units_patients) {
                                if ($units_patients === $id) {
                                    $equals = true;
                                    break;
                                }
                            }

                            if (!$equals) array_push($health_units_patients, $id);

                            $caretaker_patients = new Paciente_Utilizador();
                            $caretaker_patients->paciente_id = intval($v);
                            $caretaker_patients->utilizador_id = $id_caretaker;
                            $caretaker_patients->ativo = true;
                            $caretaker_patients->log_utilizador_id = auth()->user()->id;

                            if (!$caretaker_patients->save()) {
                                $saved = false;
                                break;
                            }
                        }

                        foreach ($health_units_patients as $units_patients) {
                            $caretaker_health_units = new User_Health_Unit();
                            $caretaker_health_units->utilizador_id = $id_caretaker;
                            $caretaker_health_units->unidade_saude_id = $units_patients;
                            $caretaker_health_units->ativo = true;
                            $caretaker_health_units->log_utilizador_id = auth()->user()->id;

                            if (!$caretaker_health_units->save()) {
                                $saved = false;
                                break;
                            }
                        }
                    } else $saved = false;
                } else $saved = false;

                if ($saved) {
                    redirect('caretakers_list')->with('c_inserted', true);
                    return json_encode([
                        "success" => true,
                        "insertion_error" => false,
                        "validation_errors" => null
                    ]);
                } else
                    return json_encode([
                        "success" => false,
                        "insertion_error" => true,
                        "validation_errors" => null
                    ]);
            } catch (Exception $e) {
                return json_encode([
                    'success' => false,
                    'insert_errors' => true,
                    'validate_errors' => null
                ]);
            }
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            "caretaker_name" => "required",
            "caretaker_email" => "required|email",
            "caretaker_password" => "required"
        ]);
        $cuidador = Cuidador::find($request->id);
        $cuidador->nome = $request->nome_edit;
        $cuidador->log_utilizador_id = auth()->user()->id;
        $cuidador->data_update = date('Y-m-d H:i:s');
        $cuidador->save();

        return response()->json([
            'status' => 'ok',
            'redirect' => 'caretakers_list',
        ]);
    }

    public function destroy($id)
    {
        $cuidador = Cuidador::find($id);
        $cuidador->ativo = false;
        $cuidador->log_utilizador_id = auth()->user()->id;
        $cuidador->data_update = date('Y-m-d H:i:s');
        $cuidador->save();

        return response()->json([
            'status' => 'ok',
            'redirect' => 'caretakers_list',
        ]);
    }
}
