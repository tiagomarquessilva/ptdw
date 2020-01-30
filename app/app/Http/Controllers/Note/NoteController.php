<?php

namespace App\Http\Controllers\Note;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use DB;
use Carbon\Carbon;
use App\Nota;
use App\Utilizador;
use Illuminate\Support\Facades\Auth;

class NoteController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index($id)
    {

        try{
            $notes = DB::table('nota')
            ->select('nota.*')
            ->where('nota.ativo','=',true)
            ->where('nota.paciente_id','=',$id)
            ->get();
            return response()->json([
                'status'   => 'ok',
                'note'     => $notes,
                //'by'       => $note_creator_name->name
            ]);
        }catch(\Illuminate\Database\QueryException $ex){
            Log::debug($ex);
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }
    }

    public function store(Request $request)
    {
        try
        {
            DB::beginTransaction();
            $data = $request->all();
            $note_id = DB::table('nota')->insertGetId(
                [
                    'nome'        => $data['note_title'],
                    'descricao'   => $data['note'],
                    'criado_por'  => 0,//\Auth::id(),
                    'paciente_id' => $data['paciente_id'],
                    'log_utilizador_id' => Auth::user()->id
                ]
            );
            DB::commit();
            $newly_note = Nota::findOrFail($note_id);
            //$note_creator_name = Utilizador::findOrFail(\Auth::id());

            return response()->json([
                'status'   => 'ok',
                'note'     => $newly_note
                //'by'       => $note_creator_name->nome
            ]);
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
            $result = DB::table('nota')
                ->where('id', '=', $id)
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
