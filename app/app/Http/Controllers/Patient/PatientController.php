<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use DB;
use Log;
use Validator;
use Illuminate\Support\Facades\Auth;
use App\Doenca;
use App\Patient;
use App\Musculo;
use App\Nota;
use App\Doenca_Paciente;
use App\Paciente_Musculo;
use Carbon\Carbon;

class PatientController extends Controller
{

    public function __construct()
    {
        $verificar_permissoes = "verificar_permissoes:" . config('Utilizador_Tipo.2') . "," . config('Utilizador_Tipo.3');
        $this->middleware($verificar_permissoes);
        $this->middleware("verificar_permissoes:" . config('Utilizador_Tipo.2'))->only(["store","update","destroy"]);
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        try{
            $patients = DB::table('paciente')
            ->select('paciente.*')
            ->where('paciente.ativo','=', true)
            ->get();

            foreach($patients as $patient) {
                $diseases = DB::table('doenca')
                ->select('doenca.nome')
                ->join('doenca_paciente', 'doenca_paciente.doenca_id', '=', 'doenca.id')
                ->where('doenca_paciente.paciente_id','=', $patient->id)
                ->pluck('doenca.nome');
                $muscles = DB::table('musculo')
                ->select('musculo.nome')
                ->join('paciente_musculo', 'paciente_musculo.musculo_id', '=', 'musculo.id')
                ->where('paciente_musculo.paciente_id','=', $patient->id)
                ->pluck('musculo.nome');
                $patient->doencas = implode(',',$diseases->all());
                $patient->musculos = implode(',',$muscles->all());
            }
        }catch(\Illuminate\lDatabase\QueryException $ex){
            #TODO: log the message to an appropiate folder or file.
            Log::debug($ex);
        }
        //dd($patients);

        return view('pages.pacients.index')->with([
            'name' => 'Pacientes',
            'pacientes' => $patients
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        /*$bdate   = $request->patient_birth_date;
        $ddate   = $request->patient_diagnosis_date;
        $name    = $request->patient_name;
        $gender  = $request->patient_gender;
        $disease = $request->patient_disease;
        $muscle  = $request->patient_muscle;

        # In order to change the date format coming from database to
        # one recognized by the laravel validator
        $request->replace([
            'patient_name' => $name,
            'patient_gender' => $gender,
            'patient_disease' => $disease,
            'patient_muscle' => $muscle,
            'patient_birth_date' => date('m/d/Y', strtotime($bdate)),
            'patient_diagnosis_date' => date('m/d/Y', strtotime($ddate))
        ]);*/
        $rules = [
            'patient_name' => 'required|max:255',
            'patient_gender' => 'required',
            'patient_birth_date' => 'date_format:d/m/Y|required|before:today',
            'patient_diagnosis_date' => 'date_format:d/m/Y|required|after_or_equal:patient_birth_date|before:today',
        ];

        #TODO: get this messages from a translation file
        $messages = [
            'patient_name.required' => 'O campo nome é de preenchimento obrigatório',
            'patient_birth_date.required' => 'O campo data de nascimento é de preenchimento obrigatório',
            'patient_diagnosis_date.required' => 'O campo data de diagnóstico é de preenchimento obrigatório',
            'patient_birth_date.before' => 'A data de nascimento não pode ser superior à data atual',
            'patient_diagnosis_date.after_or_equal' => 'A data de diagnóstico tem que ser igual ou posterior à data de nascimento',
            'patient_diagnosis_date.before' => 'A data de diagnóstico tem que ser inferior à data atual',
        ];

        $valid = Validator::make($request->all(),$rules, $messages);

        if(!$valid->passes()){
            return response()->json(['error'=>$valid->errors()->all()]);
        }

        $data = $request->request->all();
        try
        {
            DB::beginTransaction();

            $patient_id = DB::table('paciente')->insertGetId(
                [
                    'nome' => $data['patient_name'],
                    'sexo' => $data['patient_gender'][0],
                    'data_nascimento' => $data['patient_birth_date'],
                    'data_diagnostico' => $data['patient_diagnosis_date'],
                    'ativo' => true,
                    'log_utilizador_id' => Auth::user()->id,
                    'data_registo' => now()
                ]
            );
            $diseases_from_form = $data['patient_disease'];
            $diease_names = [];
            foreach ($diseases_from_form as $disease) {
                # Must make sure that the option tag in the dropdown does have values equal to those
                # present in the column nome_codigo of the doencas
                $disease_record  = DB::table('doenca')->where('nome',$disease)->first();
                array_push($diease_names, $disease_record->nome);
                $patient_disease = DB::table('doenca_paciente')->insert(
                    [
                        'paciente_id' => $patient_id,
                        'doenca_id'   => $disease_record->id,
                    ]
                );
            }


            $muscles_from_form = $data['patient_muscle'];
            $muscle_names = [];
            foreach ($muscles_from_form as $muscle) {
                # Must make sure that the option tag in the dropdown does have values equal to those
                # present in the column nome_codigo of the muscles
                $muscle_record  = DB::table('musculo')->where('nome',$muscle)->first();
                array_push($muscle_names, $muscle_record->nome);
                $patient_muscle = DB::table('paciente_musculo')->insert(
                    [
                        'paciente_id' => $patient_id,
                        'musculo_id'  => $muscle_record->id,
                    ]
                );
            }
            DB::commit();
            $newly_patient = Patient::findOrFail($patient_id);
            return response()->json([
                'status'   => 'ok',
                'redirect' => '/lista_de_pacientes',
                'patient'  => $newly_patient,
                'muscle'   => implode(',',$muscle_names),
                'disease'  => implode(',',$diease_names)
            ]);
        }catch(Exception $e)
        {
            DB::rollBack();
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }
    }


    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        $data  = $request->all();
        $rules = [
            'patient_name_edit' => 'required|max:255',
            'patient_gender_edit' => 'required',
            'patient_birth_date_edit' => 'date_format:d/m/Y|required|before:today',
            'patient_diagnosis_date_edit' => 'date_format:d/m/Y|required|after_or_equal:patient_birth_date_edit|before:today',
        ];

        #TODO: get this messages from a translation file
        $messages = [
            'patient_name_edit.required' => 'O campo nome é de preenchimento obrigatório',
            'patient_birth_date_edit.required' => 'O campo data de nascimento é de preenchimento obrigatório',
            'patient_diagnosis_date_edit.required' => 'O campo data de diagnóstico é de preenchimento obrigatório',
            'patient_birth_date_edit.before' => 'A data de nascimento não pode ser superior à data atual',
            'patient_diagnosis_date_edit.after_or_equal' => 'A data de diagnóstico tem que ser igual ou posterior à data de nascimento',
            'patient_diagnosis_date_edit.before' => 'A data de diagnóstico tem que ser inferior à data atual',
        ];

        $valid = Validator::make($data,$rules, $messages);

        if(!$valid->passes()){
            return response()->json(['error'=>$valid->errors()->all()]);
        }

        try
        {
            DB::beginTransaction();
            $result = DB::table('paciente')
                ->where('id', $id)
                ->update([
                    'nome' => $data['patient_name_edit'],
                    'sexo' => $data['patient_gender_edit'][0],
                    'data_nascimento' => $data['patient_birth_date_edit'],
                    'data_diagnostico' =>$data['patient_diagnosis_date_edit']
                    //'data_nascimento' => date("Y-m-d",strtotime($data['patient_birth_date_edit'])),
                    //'data_diagnostico' => date("Y-m-d",strtotime($data['patient_diagnosis_date_edit'])),
                ]);

            $prev_diseases_patient_rel = DB::table('doenca_paciente')
                ->where('paciente_id', $id)
                ->delete();

            $prev_muscles_patient_rel = DB::table('paciente_musculo')
                ->where('paciente_id', $id)
                ->delete();

            DB::commit();
        }catch(Exception $e)
        {
            DB::rollBack();
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }

        try{
            DB::beginTransaction();
            $diseases_from_form = $data['patient_disease_edit'];
            $diease_names = [];
            foreach ($diseases_from_form as $disease) {
                # Must make sure that the option tag in the dropdown does have values equal to those
                # present in the column nome_codigo of the doencas
                $disease_record  = DB::table('doenca')
                    ->where('nome',$disease)
                    ->first();
                array_push($diease_names, $disease_record->nome);
                $to_insert = DB::table('doenca_paciente')
                ->insert([
                    'paciente_id' => $id,
                    'doenca_id'   => $disease_record->id,
                ]);
            }


            $muscles_from_form = $data['patient_muscle_edit'];
            $muscle_names = [];
            foreach ($muscles_from_form as $muscle) {
                # Must make sure that the option tag in the dropdown does have values equal to those
                # present in the column nome_codigo of the muscles
                $muscle_record  = DB::table('musculo')->where('nome',$muscle)->first();
                array_push($muscle_names, $muscle_record->nome);
                $patient_muscle = DB::table('paciente_musculo')->insert(
                    [
                        'paciente_id' => $id,
                        'musculo_id'  => $muscle_record->id,
                    ]
                );
            }
            DB::commit();
            $patient = Patient::findOrFail($id);
            return response()->json([
                'status'   => 'ok',
                'redirect' => '/lista_de_pacientes',
                'patient'  => $patient,
                'muscle'   => implode(',',$muscle_names),
                'disease'  => implode(',',$diease_names)
            ]);
            /*return response()->json(
                [
                    'success' => 'ok',
                    'result' => $patient,
                    'url'=> '/lista_de_pacientes'

                ]);*/
        }catch(Exception $e)
        {
            DB::rollBack();
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }

    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        try{
            DB::beginTransaction();
            $result = DB::table('paciente')
                ->where('id', $id)
                ->update(['ativo' => false]);
            DB::commit();
            return response()->json([
                'status' => 'ok'
            ]);
        }catch(Exception $e)
        {
            DB::rollBack();
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }
    }
}
