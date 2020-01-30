<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Musculo extends Model
{
    protected $table = "musculo";

    // relacao com tablea intermedia
    public function paciente()
    {
        return $this->belongsToMany(Paciente::class)->using(Paciente_Musculo::class);
    }
}
