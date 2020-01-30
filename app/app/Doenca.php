<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Doenca extends Model
{
    protected $table = "doenca";

    // 1 relacao com uma tabela intermedia
    public function paciente()
    {
        return $this->belongsToMany(Paciente::class)->using(Doenca_Paciente::class);
    }
}
