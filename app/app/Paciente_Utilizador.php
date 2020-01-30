<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Paciente_Utilizador extends Model
{
    protected $table = "paciente_utilizador";
    public $timestamps = false;
    // tabela intermedia

    // muitos paciente_utilizador para 1 relacao_paciente
    // public function paciente_utilizador(){
    //     return $this->hasMany(Paciente_Utilizador::class);
    // }
}
