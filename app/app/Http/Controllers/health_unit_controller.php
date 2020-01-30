<?php

namespace App\Http\Controllers;

use App\health_unit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use stdClass;

class health_unit_controller extends Controller
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
        $health_units = health_unit::where('ativo', true)->get();
        return view("pages.health_unit_list")->with(['name' => 'Unidades de Saúde', 'health_units' => $health_units]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        // Validar entradas

        $validator = Validator::make($request->all(), [
            'health_unit_name' => 'required',
            'health_unit_address' => 'required',
            'health_unit_contact' => 'required|unique:unidade_saude,telefone',
            'health_unit_email' => 'required|unique:unidade_saude,email'
        ]);

        // erro se validação falha, se nao guarda unidade de saude
        if ($validator->fails()) {
            return json_encode([
                "success" => false,
                "insertion_error" => false,
                "validation_errors" => $validator->errors()
            ]);
        } else {
            $health_unit = new health_unit;
            $health_unit->nome = $request->health_unit_name;
            $health_unit->morada = $request->health_unit_address;
            $health_unit->telefone = $request->health_unit_contact;
            $health_unit->email = $request->health_unit_email;
            $health_unit->ativo = true;
            $health_unit->log_utilizador_id = auth()->user()->id;

            if ($health_unit->save()) {
                redirect('health_units')->with('health_unit_inserted', true);
                return json_encode([
                    "success" => true,
                    "insertion_error" => false,
                    "validation_errors" => new stdClass()
                ]);
            } else {
                return json_encode([
                    "success" => false,
                    "insertion_error" => true,
                    "validation_errors" => new stdClass()
                ]);
            }
        }
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
        // Validar entradas

        $validator = Validator::make($request->all(), [
            'edit_health_unit_name' => 'required',
            'edit_health_unit_address' => 'required',
            'edit_health_unit_contact' => ['required', Rule::unique('unidade_saude', 'telefone')->ignore($id)],
            'edit_health_unit_email' => ['required', Rule::unique('unidade_saude', 'email')->ignore($id)]
        ]);

        // erro se validação falha, se nao guarda unidade de saude
        if ($validator->fails()) {
            return json_encode([
                "success" => false,
                "insertion_error" => false,
                "validation_errors" => $validator->errors()
            ]);
        } else {
            $health_unit = health_unit::find($id);
            $health_unit->nome = $request->edit_health_unit_name;
            $health_unit->morada = $request->edit_health_unit_address;
            $health_unit->telefone = $request->edit_health_unit_contact;
            $health_unit->email = $request->edit_health_unit_email;
            $health_unit->ativo = true;
            $health_unit->data_update = date('Y-m-d H:i:s');
            $health_unit->log_utilizador_id = auth()->user()->id;

            if ($health_unit->save()) {
                redirect('health_units')->with('health_unit_updated', true);
                return json_encode([
                    "success" => true,
                    "insertion_error" => false,
                    "validation_errors" => new stdClass()
                ]);
            } else {
                return json_encode([
                    "success" => false,
                    "insertion_error" => true,
                    "validation_errors" => new stdClass()
                ]);
            }
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
        $health_unit = health_unit::find($id);
        $health_unit->ativo = false;
        $health_unit->data_update = date('Y-m-d H:i:s');
        $health_unit->log_utilizador_id = auth()->user()->id;

        if ($health_unit->save()) {
            return redirect('health_units')->with('health_unit_deleted', true);
        } else {
            return redirect('health_units')->with('health_unit_deleted', false);
        }
    }
}
