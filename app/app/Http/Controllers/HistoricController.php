<?php

namespace App\Http\Controllers;

use App\health_unit;
use App\Patient;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HistoricController extends Controller
{

    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:". config('Utilizador_Tipo.2') .",".config('Utilizador_Tipo.3');
        $this->middleware($verificar_permissoes);
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $health_units = health_unit::all();
        $patients = Patient::all();
        return view('pages.historic')->with(['health_units' => $health_units, 'patients' => $patients, 'name' => 'Histórico']);
    }

    private function setArray($array, $element)
    {
        $tmp = array();
        foreach ($array as $a) array_push($tmp, $a[$element]);
        return $tmp;
    }

    /**/

    /**
     * @return array
     */
    public function get_historic_patients()
    {
        try {
            $h_patients = DB::table('historico_pacientes')->get(['nome', 'equipamento', 'valor_emg', 'valor_bc'])->map(function ($p) {
                return [
                    'nome' => $p->nome,
                    'equipamentos' => json_decode($p->equipamento, true),
                    'valor_emg' => $p->valor_emg,
                    'valor_bc' => $p->valor_bc,
                ];
            });

            return json_encode([
                'success' => true,
                'historic' => ['names' => $this->setArray($h_patients, 'nome'), 'equipments' => $this->setArray($h_patients, 'equipamentos'),
                    'emg' => $this->setArray($h_patients, 'valor_emg'), 'bc' => $this->setArray($h_patients, 'valor_bc')]
            ]);
        } catch (Exception $e) {
            return json_encode([
                'success' => false,
                'historic' => null
            ]);
        }
    }

    /**
     * @return array
     */
    public function get_historic_patient($id)
    {
        try {
            $h_patient = DB::table('historico_valores AS h')
                ->join('equipamentos AS e', 'e.id', '=', 'h.equipamento_id')
                ->selectRaw('e.nome AS equipamentos')
                ->selectRaw(DB::raw('json_build_object(\'t\',to_char(h.data_registo, \'YYYY-MM-DD HH24:MI:SS\'),\'y\',round(h.emg::numeric, 2)) AS valor_emg'))
                ->selectRaw(DB::raw('json_build_object(\'t\',to_char(h.data_registo, \'YYYY-MM-DD HH24:MI:SS\'),\'y\',round(h.bc::numeric, 2)) AS valor_bc'))
                ->where('h.paciente_id', '=', $id)
                ->groupBy(['e.nome', 'h.data_registo', 'h.emg', 'h.bc'])
                ->orderBy('h.data_registo')
                ->get()
                ->map(function ($p) {
                    return [
                        'valor_emg' => json_decode($p->valor_emg, true),
                        'valor_bc' => json_decode($p->valor_bc, true),
                        'equipamentos' => $p->equipamentos
                    ];
                });

            return json_encode([
                'success' => true,
                'historic' => ['emg' => $this->setArray($h_patient, 'valor_emg'), 'bc' => $this->setArray($h_patient, 'valor_bc'),
                    'equipments' => $this->setArray($h_patient, 'equipamentos')]
            ]);
        } catch (Exception $e) {
            return json_encode([
                'success' => false,
                'historic' => $e->getMessage()
            ]);
        }
    }

    public function get_historic_health_units($id)
    {
        try {
            $h_patients = DB::table('historico_unidades_saude')
                ->selectRaw(DB::raw('nome'))
                ->selectRaw(DB::raw('jsonb_agg(DISTINCT equipamento ORDER BY equipamento) AS equipamento'))
                ->selectRaw(DB::raw('round(AVG(emg)::numeric, 2) AS valor_emg'))
                ->selectRaw(DB::raw('round(AVG(bc)::numeric, 2) AS valor_bc'))
                ->groupBy('nome')
                ->where('u_s_id', '=', $id)
                ->get(['nome', 'equipamento', 'valor_emg', 'valor_bc'])->map(function ($p) {
                    return [
                        'nome' => $p->nome,
                        'equipamentos' => json_decode($p->equipamento, true),
                        'valor_emg' => $p->valor_emg,
                        'valor_bc' => $p->valor_bc,
                    ];
                });

            return json_encode([
                'success' => true,
                'historic' => ['names' => $this->setArray($h_patients, 'nome'), 'equipments' => $this->setArray($h_patients, 'equipamentos'),
                    'emg' => $this->setArray($h_patients, 'valor_emg'), 'bc' => $this->setArray($h_patients, 'valor_bc')]
            ]);
        } catch (Exception $e) {
            return json_encode([
                'success' => false,
                'historic' => $e->getMessage()
            ]);
        }
    }
}
