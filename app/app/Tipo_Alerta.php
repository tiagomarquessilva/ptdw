<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Tipo_Alerta extends Model
{
    protected $table = "tipo_alerta";

    // um tipo_alerta para muitos alertas
    public function alertas()
    {
        return $this->hasMany(Alerta::class);
    }

}
