<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Lembrete extends Model
{
    protected $table = "lembrete";

    // muitos lembretes para 1 paciente
    public function paciente()
    {
        return $this->belongsTo(Paciente::class);
    }
}
