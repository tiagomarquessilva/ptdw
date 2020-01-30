<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Patient extends Model
{
    protected $table = 'paciente';

// um paciente para muitos alertas
    public function alertas()
    {
        return $this->hasMany(Alerta::class);
    }

    // um paciente para muitas notas
    public function nota()
    {
        return $this->hasMany(Nota::class);
    }

    // um paciente para muitos lembretes
    public function lembrete()
    {
        return $this->hasMany(Lembrete::class);
    }

    // um paciente para muuitos historicos configurações
    public function historico_configuracoes()
    {
        return $this->hasMany(Historico_Configuracoes::class);
    }

    // um paciente para muitos historicos valores
    public function historico_valores()
    {
        return $this->hasMany(Historico_Valores::class);
    }

    // um paciente para muitos pedido ajuda
    public function pedido_ajuda()
    {
        return $this->hasMany(Pedido_Ajuda::class);
    }

    // muitos pacientes para muitas doencas atraves de tabela intermedia
    public function doencas()
    {
        // return $this->belongsToMany('App\Doenca', 'App\Doenca_Paciente');
        return $this->belongsToMany(Doenca::class)->using(Doenca_Paciente::class);
    }

    // muitos pacientes para muitos musculos atraves de tabela intermedia
    public function musculos()
    {
        return $this->belongsToMany(Musculo::class)->using(Paciente_Musculo::class);
    }

    // muitos pacientes para muitos utilizadores atraves de tabela intermedia
    public function utilizador()
    {
        return $this->belongsToMany(Utilizador::class)->using(Paciente_Utilizador::class);
    }
}
