<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Alerta extends Model
{
    protected $table = "alerta";

    // muitos alertas tem o mesmo tipo_alerta
    public function tipo_alerta()
    {
        return $this->belongsTo(Tipo_Alerta::class);
    }

    // muitos alertas tem a mesma descricao_alerta
    public function descricao_alertas()
    {
        return $this->belongsTo(Descricao_Alerta::class);
    }

    // muitos alertas tem o mesmo paciente
    public function paciente()
    {
        return $this->belongsTo(Paciente::class);
    }
}
