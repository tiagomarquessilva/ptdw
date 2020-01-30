<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Nota extends Model
{
    protected $table = "nota";

    // muitas notas para 1 paciente
    public function paciente()
    {
        return $this->belongsTo(Paciente::class);
    }
}
