<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Historico_Valores extends Model
{
    protected $table = "historico_valores";

    protected $guarded = ["id"];

    public $timestamps = false;

    // muitos historicos para 1 equipamento
    public function equipamento()
    {
        return $this->belongsTo(Equipamento::class);
    }

    // muitos historicos para 1 paciente
    public function paciente()
    {
        return $this->belongsTo(Paciente::class);
    }
}
