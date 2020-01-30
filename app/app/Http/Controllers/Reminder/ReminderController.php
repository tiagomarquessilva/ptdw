<?php

namespace App\Http\Controllers\Reminder;

use Illuminate\Http\Request;
use App\Lembrete;
use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;

class ReminderController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        try{
            $reminders = DB::table('lembrete')
            ->select('lembrete.*')
            ->where('lembrete.ativo','=',true)
            ->where('lembrete.paciente_id','=',$id)
            ->get();
            return response()->json([
                'status'   => 'ok',
                'reminder'     => $reminders
            ]);
        }catch(\Illuminate\lDatabase\QueryException $ex){
            Log::debug($ex);
            return redirect()->back()
                ->withErrors(['error' => $e->getMessage()]);
        }
    }


    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        try
        {
            dd($request->all());
            DB::beginTransaction();
            $data = $request->all();
            $reminder = DB::table('lembrete')->insert(
                [
                    'nome'              => $data['reminder'],
                    'data_a_notificar'  => $data['date_to_notify'],
                    'hora_a_notificar'  => $data['time_to_notify'],
                    'log_utilizador_id' => Auth::user()->id
                ]
            );
            DB::commit();
            $last_inserted_reminder_id = DB::getPdo()->lastInsertId();
            $newly_reminder = Reminder::findOrFail($last_inserted_reminder_id);
            return response()->json([
                'status'   => 'ok',
                'reminder'     => $newly_reminder
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
            $result = DB::table('lembrete')
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
