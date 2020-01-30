<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Tipo extends Model
{
    protected $table = "tipos";

    /**
     * Utilizadores com este tipo de conta
     */
    public function utilizadores()
    {
        return $this->belongsToMany(Utilizador::class)->using(Utilizador_Tipo::class);
    }
}


