<?php

namespace App;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class Utilizador extends Authenticatable
{
    protected $table = 'utilizador';
    public $timestamps = false;
    use Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'nome', 'email', 'password',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 'remember_token',
    ];

    /**
     * The attributes that should be cast to native types.
     *
     * @var array
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    /**
     * tipo de conta
     */
    public function tipos()
    {
        return $this->belongsToMany(Tipo::class, 'utilizador_tipo');
    }

    public function temTipos($tipos)
    {
        return null !== $this->tipos()->whereIn("nome", $tipos)->first();
    }

    public function temTipo($tipo)
    {
        return null !== $this->tipos()->where("nome", $tipo)->first();
    }

    // um utilizador para muitos pedido ajuda
    public function pedido_ajuda()
    {
        return $this->hasMany(Pedido_Ajuda::class);
    }

    // muitos utilizadores para 1 funcao
    private function funcao()
    {
        return $this->belongsTo(Funcao::class);
    }

    // muitos utilizadores para muitos pacientes atraves de tabela intermedia
    public function pacientes()
    {
        return $this->belongsToMany(Paciente::class)->using(Paciente_Utilizador::class);
    }

    // muitos utilizadores para muitas unidades_saude atraves de tabela intermedia
    public function unidade_saude()
    {
        return $this->belongsToMany(Unidade_Saude::class)->using(Utilizador_Unidade_Saude::class);
    }
}

