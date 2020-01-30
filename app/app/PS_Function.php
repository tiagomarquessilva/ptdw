<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class PS_Function extends Model
{
    protected $table = 'funcao';

// 1 funcao para muitos utilizadores
    private function utilizador()
    {
        return $this->hasMany(Utilizador::class);
    }
}
