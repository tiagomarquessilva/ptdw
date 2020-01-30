<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Pedido_Ajuda extends Model
{
    protected $table = "pedido_ajuda";

    // muitos pedidos_ajuda para 1 paciente
    public function paciente()
    {
        return $this->belongsTo(Paciente::class);
    }

    // muitos pedidos de ajuda para 1 utilizador
    public function utilizador()
    {
        return $this->belongsTo(Utilizador::class);
    }
}
