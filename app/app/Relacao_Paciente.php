<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Relacao_Paciente extends Model
{
    protected $table = "relacao_paciente";

    // tabela "perdida" ligada a tabela intermedia

    // uma relacao paciente para muitos pacientes utilizadores
    public function paciente_utilizador()
    {
        return $this->hasMany(Paciente_Utilizador::class);
    }
}
