<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class notifications extends Model
{
    protected $table = "alerta";
    public $timestamps = false;

    public function scopeFormatted($query)
    {
        /*
        SELECT alerta.data_registo as date, tipo_alerta.nome as type, descricao_alerta.mensagem as message, paciente.nome as pacient_name, resolvido as solved, alerta.comentario as commentary
        FROM alerta
        JOIN descricao_alerta ON descricao_alerta.id = alerta.descricao_alerta_id
        JOIN paciente ON paciente.id = alerta.paciente_id
        JOIN paciente_utilizador ON paciente_utilizador.paciente_id = paciente.id
        JOIN tipo_alerta ON tipo_alerta.id = alerta.tipo_alerta_id
        ORDER BY date desc;
        */

        return $query
            ->join("descricao_alerta", "alerta.descricao_alerta_id", "=", "descricao_alerta.id")
            ->join("paciente", "alerta.paciente_id", "=", "paciente.id")
            ->join("tipo_alerta", "alerta.tipo_alerta_id", "=", "tipo_alerta.id")
            ->join("paciente_utilizador", "paciente_utilizador.paciente_id", "=", "paciente.id")
            ->select("alerta.id as id", "paciente_utilizador.utilizador_id as user_id", "alerta.data_registo as date", "tipo_alerta.nome as type", "descricao_alerta.mensagem as message", "paciente.nome as pacient_name", "resolvido as solved", "alerta.comentario as commentary")
            ->latest("alerta.data_registo");
    }

}
