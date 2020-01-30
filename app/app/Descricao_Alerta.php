<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Descricao_Alerta extends Model
{
    protected $table = "descricao_alerta";

    // um tipo_alerta para muitos alertas
    public function alertas()
    {
        return $this->hasMany(Alerta::class);
    }
}
