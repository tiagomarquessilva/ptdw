<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Unidade_Saude extends Model
{
    protected $table = "unidade_saude";

    // muitas unidades_saude para muitos utilizadores atraves de tabela intermedia
    public function utilizadores()
    {
        return $this->belongsToMany(Utilizador::class)->using(Utilizador_Unidade_Saude::class);
    }
}
