<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Equipamento extends Model
{
    protected $hidden = ['data_registo','data_update'];
    public $timestamps = false;
    protected $table = "equipamentos";
    protected $fillable = ['nome','access_token','log_utilizador_id','ativo'];

    // 1 equipamento para muitos historicos de configurações
    public function historico_configuracoes()
    {
        return $this->hasMany(Historico_Configuracoes::class);
    }

    // 1 equipamento para muitos historicos de valores
    public function historico_valores()
    {
        return $this->hasMany(Historico_Valores::class);
    }

    public function esta_associado()
    {
        return null !== $this->historico_configuracoes()->where("esta_associado", true)->first() ? "sim" : "não";
    }
}
