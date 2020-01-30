<?php

namespace App;

use Illuminate\Database\Eloquent\Relations\Pivot;

class Utilizador_Tipo extends Pivot
{
    protected $table = "utilizador_tipo";
    public $timestamps = false;
}

    