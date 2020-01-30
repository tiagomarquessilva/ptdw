<?php

namespace App\Http\Controllers;

use App\notifications;
use App\Equipamento;
use App\Historico_Configuracoes;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use stdClass;

class notifications_controller extends Controller
{

    public function index()
    {
        return notifications::formatted()->where('paciente_utilizador.utilizador_id', Auth::id())->get();
    }

    public function index_unsolved_notifications()
    {   
        return notifications::formatted()->where([['paciente_utilizador.utilizador_id', '=', Auth::id()], ['alerta.resolvido', '=', false]])->get();
    }

    public function index_unsolved_notifications_after(Request $request)
    {
        $notifications = notifications::formatted()->where([['paciente_utilizador.utilizador_id', '=', Auth::id()], ['alerta.data_registo', '>', $request->date]])->get();
        return $notifications;
    }

    public function store_notification(Request $request)
    {
        // Validar entradas
        $validator = Validator::make($request->all(), [
            'access_token' => 'required|string|max:20',
            'type_id' => 'required|integer',
            'message_id' => 'required|integer',
            'date' => 'required|date'
        ]);

        // erro se validação falha, se nao guarda unidade de saude
        if ($validator->fails()) {
            $json = [
                "success" => false,
                "insertion_error" => false,
                "validation_errors" => $validator->errors()
            ];
        } else {

            //verificar token de acesso e buscar ID
            $equipment = Equipamento::where("access_token", $request->access_token)->firstOrFail();

            //ir buscar ID paciente
            $history = Historico_Configuracoes::where("equipamento_id", $equipment["id"])
                ->where("esta_associado", true)
                ->latest("id")
                ->get()
                ->first();

            $patient_id = $history["paciente_id"];

            // inserir na bd
            try {
                $alert = new notifications;
                $alert->comentario = null;
                $alert->data_registo = $request->date;
                $alert->descricao_alerta_id = $request->message_id;
                $alert->paciente_id = $patient_id;
                $alert->resolvido = false;
                $alert->tipo_alerta_id = $request->type_id;


                if ($alert->save()) {
                    $json = [
                        "success" => true,
                        "insertion_error" => false,
                        "validation_errors" => new stdClass()
                    ];
                } else {
                    $json = [
                        "success" => false,
                        "insertion_error" => true,
                        "validation_errors" => new stdClass()
                    ];
                }
            } catch (QueryException $ex) {
                $json = [
                    "success" => false,
                    "insertion_error" => true,
                    "validation_errors" => new stdClass()
                ];
            }
        }

        return json_encode($json);
    }

    public function update(Request $request, $id)
    {
        // Validar entradas

        $validator = Validator::make($request->all(), [
            'solved' => 'boolean'
        ]);

        // erro se validação falha, se nao guarda unidade de saude
        if ($validator->fails()) {
            return json_encode([
                "success" => false,
                "insertion_error" => false,
                "validation_errors" => $validator->errors()
            ]);
        } else {
            $notification = notifications::find($id);
            $notification->comentario = $request->commentary;
            $notification->resolvido = $request->solved;

            if ($notification->save()) {
                redirect('/user_profile')->with('notifications_updated', true);
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
}
